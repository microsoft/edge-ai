#!/usr/bin/env python3
"""Synthetic sensor simulator for the Azure IoT Operations MQTT broker.

Publishes deterministic-when-seeded vibration, acoustic, and temperature
readings to versioned topics, with CloudEvents attributes carried as MQTT v5
user properties. An anomaly toggle shifts every signal from a healthy band to a
faulty band and can optionally be changed at runtime through a control topic.
"""

from __future__ import annotations

import json
import logging
import math
import random
import signal
import time
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import UTC, datetime
from types import FrameType

import paho.mqtt.client as mqtt
from models import (
    AcousticReading,
    ControlCommand,
    HealthState,
    Reading,
    ScalarReading,
    SensorModality,
    SimulatorConfig,
    describe_config_error,
)
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties
from pydantic import ValidationError

logger = logging.getLogger("sensor-simulator")

SAT_AUTH_METHOD = "K8S-SAT"
CONTENT_TYPE = "application/json"
MAX_CONTROL_BYTES = 1024
INITIAL_RECONNECT_DELAY = 1.0
MAX_RECONNECT_DELAY = 30.0
COUNTERS_INTERVAL_SECONDS = 60.0

UNITS = {
    SensorModality.VIBRATION: "mm/s",
    SensorModality.TEMPERATURE: "degC",
}


class SignalGenerator:
    """Builds synthetic readings from a seeded random source."""

    def __init__(self, config: SimulatorConfig, rng: random.Random) -> None:
        self._config = config
        self._rng = rng

    def reading(self, modality: SensorModality, faulty: bool, timestamp: datetime) -> Reading:
        """Return one reading for the modality in the requested state."""
        common = {
            "asset_id": self._config.asset_id,
            "sensor_id": self._config.sensor_id,
            "modality": modality,
            "health_state": HealthState.FAULTY if faulty else HealthState.HEALTHY,
            "timestamp": _rfc3339(timestamp),
        }
        if modality is SensorModality.ACOUSTIC:
            return AcousticReading(
                **common,
                sample_rate=self._config.acoustic_sample_rate,
                samples=self._acoustic_samples(faulty),
            )
        return ScalarReading(**common, value=self._scalar(modality, faulty), unit=UNITS[modality])

    def _scalar(self, modality: SensorModality, faulty: bool) -> float:
        config = self._config
        if modality is SensorModality.TEMPERATURE:
            center = config.temperature_faulty_c if faulty else config.temperature_healthy_c
            return round(self._rng.gauss(center, config.temperature_jitter_c), 3)
        center = config.faulty_band_center if faulty else config.healthy_band_center
        return round(self._rng.gauss(center, config.band_jitter), 4)

    def _acoustic_samples(self, faulty: bool) -> list[float]:
        rate = self._config.acoustic_sample_rate
        samples: list[float] = []
        for index in range(self._config.acoustic_sample_count):
            t = index / rate
            value = 0.12 * math.sin(2 * math.pi * 220.0 * t)
            if faulty:
                value += 0.28 * math.sin(2 * math.pi * 3200.0 * t)
            value += self._rng.gauss(0.0, 0.02)
            samples.append(round(max(-1.0, min(1.0, value)), 6))
        return samples


@dataclass
class Counters:
    """Fixed-cardinality counters logged periodically."""

    publish_enqueued: int = 0
    publish_failed: int = 0
    publish_acked: int = 0
    publish_rejected: int = 0
    control_applied: int = 0
    control_rejected: int = 0
    connects: int = 0
    by_modality: dict[str, int] = field(default_factory=dict)


@dataclass
class SimulatorState:
    """Mutable runtime state shared with MQTT callbacks."""

    inject_anomaly: bool
    connected: bool = False
    counters: Counters = field(default_factory=Counters)


def _rfc3339(moment: datetime) -> str:
    return moment.astimezone(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def publish_properties(
    config: SimulatorConfig, modality: SensorModality, event_id: str, moment: datetime
) -> Properties:
    """Return MQTT v5 PUBLISH properties carrying the CloudEvents attributes."""
    properties = Properties(PacketTypes.PUBLISH)
    properties.ContentType = CONTENT_TYPE
    properties.PayloadFormatIndicator = 1
    attributes = [
        ("specversion", "1.0"),
        ("type", f"edge-ai.sensor.{modality.value}"),
        ("source", config.event_source),
        ("id", event_id),
        ("time", _rfc3339(moment)),
        ("subject", config.asset_id),
        ("datacontenttype", CONTENT_TYPE),
    ]
    if config.data_schema:
        attributes.append(("dataschema", config.data_schema))
    properties.UserProperty = attributes
    return properties


def connect_properties(config: SimulatorConfig) -> Properties | None:
    """Return CONNECT properties for SAT enhanced authentication, if enabled.

    The token is read on every call so a reconnect uses the current projected
    service account token.
    """
    if not config.sat_file:
        return None
    with open(config.sat_file, encoding="utf-8") as handle:
        token = handle.read().strip()
    properties = Properties(PacketTypes.CONNECT)
    properties.AuthenticationMethod = SAT_AUTH_METHOD
    properties.AuthenticationData = token.encode("utf-8")
    return properties


def parse_control(payload: bytes) -> ControlCommand | None:
    """Parse a control payload, returning None when it's invalid."""
    if len(payload) > MAX_CONTROL_BYTES:
        return None
    try:
        return ControlCommand.model_validate_json(payload)
    except ValidationError:
        return None


def build_client(config: SimulatorConfig, state: SimulatorState) -> mqtt.Client:
    """Create a paho MQTT v5 client wired to the simulator state."""
    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=config.client_id,
        protocol=mqtt.MQTTv5,
    )
    if config.use_tls:
        client.tls_set(ca_certs=config.ca_file or None)

    def on_connect(client, userdata, flags, reason_code, properties) -> None:
        if reason_code.is_failure:
            logger.error("Broker rejected connection: %s", reason_code)
            return
        state.connected = True
        state.counters.connects += 1
        logger.info("Connected to %s:%s", config.broker_host, config.broker_port)
        if config.control_enabled:
            client.subscribe(config.control_topic, qos=config.qos)

    def on_disconnect(client, userdata, flags, reason_code, properties) -> None:
        state.connected = False
        logger.warning("Disconnected from broker: %s", reason_code)

    def on_publish(client, userdata, mid, reason_code, properties) -> None:
        if reason_code.is_failure:
            state.counters.publish_rejected += 1
            logger.warning("Broker rejected publish: %s", reason_code)
        else:
            state.counters.publish_acked += 1

    def on_subscribe(client, userdata, mid, reason_code_list, properties) -> None:
        for reason_code in reason_code_list:
            if reason_code.is_failure:
                logger.warning("Broker rejected control subscription: %s", reason_code)

    def on_control(client, userdata, message: mqtt.MQTTMessage) -> None:
        command = parse_control(message.payload)
        if command is None:
            state.counters.control_rejected += 1
            logger.warning("Ignored invalid control payload (%d bytes)", len(message.payload))
            return
        state.inject_anomaly = command.inject_anomaly
        state.counters.control_applied += 1
        logger.info("Anomaly injection set to %s", command.inject_anomaly)

    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_publish = on_publish
    client.on_subscribe = on_subscribe
    if config.control_enabled:
        client.message_callback_add(config.control_topic, on_control)
    return client


def publish_cycle(
    client: mqtt.Client,
    config: SimulatorConfig,
    state: SimulatorState,
    generator: SignalGenerator,
) -> None:
    """Publish one reading per configured modality."""
    faulty = state.inject_anomaly
    for modality in config.modalities:
        moment = datetime.now(UTC)
        reading = generator.reading(modality, faulty, moment)
        info = client.publish(
            config.topic_for(modality),
            reading.model_dump_json(),
            qos=config.qos,
            properties=publish_properties(config, modality, str(uuid.uuid4()), moment),
        )
        if info.rc == mqtt.MQTT_ERR_SUCCESS:
            state.counters.publish_enqueued += 1
            key = modality.value
            state.counters.by_modality[key] = state.counters.by_modality.get(key, 0) + 1
        else:
            state.counters.publish_failed += 1


class Runner:
    """Single-threaded connect, network, and publish loop.

    Driving client.loop() from here, rather than a paho network thread, lets
    every connection attempt pass fresh CONNECT properties.
    """

    def __init__(
        self,
        config: SimulatorConfig,
        client: mqtt.Client,
        state: SimulatorState,
        generator: SignalGenerator,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._config = config
        self._client = client
        self._state = state
        self._generator = generator
        self._clock = clock
        self._sleep = sleep
        self.stopping = False
        self.socket_open = False
        self.reconnect_delay = INITIAL_RECONNECT_DELAY
        self.next_connect = 0.0
        self.next_publish = clock()
        self.next_counters = clock() + COUNTERS_INTERVAL_SECONDS

    def step(self) -> None:
        """Run one iteration of the connect, network, and publish loop."""
        now = self._clock()
        if not self.socket_open and now >= self.next_connect:
            self._connect(now)

        if self.socket_open:
            rc = self._client.loop(timeout=0.1)
            if rc != mqtt.MQTT_ERR_SUCCESS:
                self.socket_open = False
                self._state.connected = False
                self._schedule_reconnect(self._clock())
            elif self._state.connected:
                self.reconnect_delay = INITIAL_RECONNECT_DELAY
        else:
            self._sleep(0.1)

        now = self._clock()
        if self._state.connected and now >= self.next_publish:
            publish_cycle(self._client, self._config, self._state, self._generator)
            self.next_publish = now + self._config.publish_interval_seconds
        if now >= self.next_counters:
            logger.info("Counters: %s", json.dumps(self._state.counters.__dict__))
            self.next_counters = now + COUNTERS_INTERVAL_SECONDS

    def run(self) -> None:
        """Loop until stop() is called, then disconnect."""
        while not self.stopping:
            self.step()
        if self.socket_open:
            self._client.disconnect()
            self._client.loop(timeout=1.0)
        logger.info("Stopped. Counters: %s", json.dumps(self._state.counters.__dict__))

    def stop(self) -> None:
        self.stopping = True

    def _connect(self, now: float) -> None:
        config = self._config
        try:
            self._client.connect(
                config.broker_host,
                config.broker_port,
                keepalive=30,
                properties=connect_properties(config),
            )
            self.socket_open = True
        except OSError as error:
            logger.warning("Connection attempt failed (%s); retrying in %.0fs", error, self.reconnect_delay)
            self._schedule_reconnect(now)

    def _schedule_reconnect(self, now: float) -> None:
        self.next_connect = now + self.reconnect_delay
        self.reconnect_delay = min(self.reconnect_delay * 2, MAX_RECONNECT_DELAY)


def run(config: SimulatorConfig) -> int:
    """Run the publish loop until SIGTERM or SIGINT and return the exit code."""
    state = SimulatorState(inject_anomaly=config.inject_anomaly)
    generator = SignalGenerator(config, random.Random(config.seed))
    try:
        client = build_client(config, state)
    except OSError as error:  # includes ssl.SSLError for an unreadable or invalid CA bundle
        logger.error("Invalid TLS configuration: %s", error)
        return 2
    runner = Runner(config, client, state, generator)

    def handle_signal(signum: int, frame: FrameType | None) -> None:
        logger.info("Received signal %s; shutting down", signum)
        runner.stop()

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    logger.info(
        "Publishing %s every %ss under %s",
        ",".join(modality.value for modality in config.modalities),
        config.publish_interval_seconds,
        config.topic_for(config.modalities[0]).rsplit("/", 1)[0],
    )
    runner.run()
    return 0


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    try:
        config = SimulatorConfig.from_env()
    except (ValidationError, ValueError) as error:
        for line in describe_config_error(error):
            logger.error("Invalid configuration: %s", line)
        return 2
    return run(config)


if __name__ == "__main__":
    raise SystemExit(main())
