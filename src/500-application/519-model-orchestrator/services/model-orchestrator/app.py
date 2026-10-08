#!/usr/bin/env python3
"""Model orchestrator for Azure IoT Operations.

Receives one request per ensemble evaluation, fans it out to every configured
model through the MQTT predict adapter, interprets each response with a typed
result adapter, and publishes one aggregate decision per request.
"""

from __future__ import annotations

import json
import logging
import re
import signal
import time
import uuid
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from types import FrameType

import paho.mqtt.client as mqtt
from models import (
    Fanout,
    OrchestratorConfig,
    aggregate,
    interpret,
    parse_predict_response_topic,
    parse_request_topic,
    request_id,
    validate_request_body,
)
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties
from pydantic import ValidationError

logger = logging.getLogger("model-orchestrator")

SAT_AUTH_METHOD = "K8S-SAT"
CONTENT_TYPE = "application/json"
RESPONSE_TYPE = "edge-ai.orchestrate.response"
PREDICT_REQUEST_TYPE = "edge-ai.predict.request"
TRACEPARENT = re.compile(r"^00-(?!0{32})[0-9a-f]{32}-(?!0{16})[0-9a-f]{16}-[0-9a-f]{2}$")
MAX_CORRELATION_DATA_LEN = 256
INITIAL_RECONNECT_DELAY = 1.0
MAX_RECONNECT_DELAY = 30.0
COUNTERS_INTERVAL_SECONDS = 60.0


@dataclass
class Counters:
    """Fixed-cardinality counters logged periodically."""

    received: int = 0
    complete: int = 0
    partial: int = 0
    failed: int = 0
    rejected: int = 0
    late: int = 0
    duplicate: int = 0
    publish_failed: int = 0
    connects: int = 0


def _rfc3339(moment: datetime) -> str:
    return moment.astimezone(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def publish_properties(
    config: OrchestratorConfig,
    event_type: str,
    subject: str,
    correlation: bytes | None,
    traceparent: str | None,
) -> Properties:
    """Return MQTT v5 PUBLISH properties with CloudEvents attributes."""
    properties = Properties(PacketTypes.PUBLISH)
    properties.ContentType = CONTENT_TYPE
    properties.PayloadFormatIndicator = 1
    attributes = [
        ("specversion", "1.0"),
        ("type", event_type),
        ("source", config.event_source),
        ("id", str(uuid.uuid4())),
        ("time", _rfc3339(datetime.now(UTC))),
        ("subject", subject),
        ("datacontenttype", CONTENT_TYPE),
    ]
    if traceparent:
        attributes.append(("traceparent", traceparent))
    # paho appends on every UserProperty assignment, so assign exactly once.
    properties.UserProperty = attributes
    if correlation:
        properties.CorrelationData = correlation
    return properties


def request_context(properties: Properties | None) -> tuple[str | None, bytes | None, str | None]:
    """Return the bounded request ID, Correlation Data, and a valid traceparent."""
    user_properties: list[tuple[str, str]] = list(getattr(properties, "UserProperty", None) or [])
    correlation = getattr(properties, "CorrelationData", None)
    if correlation is not None and len(correlation) > MAX_CORRELATION_DATA_LEN:
        correlation = None
    traceparent = next(
        (value for key, value in user_properties if key == "traceparent" and TRACEPARENT.match(value)),
        None,
    )
    return request_id(user_properties), correlation, traceparent


class Orchestrator:
    """Fan-out state machine. Every method runs on the MQTT thread."""

    def __init__(self, config: OrchestratorConfig, publish, clock=time.monotonic) -> None:
        self.config = config
        self.publish = publish
        self.clock = clock
        self.counters = Counters()
        self.pending: dict[str, Fanout] = {}
        self.specs = {model.id: model for model in config.models}

    def handle_request(self, topic: str, payload: bytes, properties: Properties | None) -> None:
        client = parse_request_topic(self.config, topic)
        if client is None:
            return
        self.counters.received += 1
        req_id, correlation, traceparent = request_context(properties)

        error = validate_request_body(payload, self.config.max_request_bytes)
        if error is None and len(self.pending) >= self.config.max_pending:
            error = "BUSY"
        if (
            error is None
            and req_id
            and any(fanout.client == client and fanout.request_id == req_id for fanout in self.pending.values())
        ):
            error = "DUPLICATE_REQUEST"
        if error is not None:
            self._reject(client, req_id, correlation, traceparent, error)
            return

        now = self.clock()
        key = uuid.uuid4().hex
        fanout = Fanout(
            correlation=key,
            client=client,
            request_id=req_id,
            request_correlation=correlation,
            traceparent=traceparent,
            started=now,
            deadline=now + self.config.timeout_seconds,
            expected=tuple(self.specs),
        )
        self.pending[key] = fanout
        for model_id in fanout.expected:
            self._publish(
                self.config.predict_request_topic(model_id),
                payload,
                publish_properties(self.config, PREDICT_REQUEST_TYPE, model_id, key.encode(), traceparent),
            )

    def handle_predict_response(self, topic: str, payload: bytes, properties: Properties | None) -> None:
        model_id = parse_predict_response_topic(self.config, topic)
        if model_id is None:
            return
        correlation = getattr(properties, "CorrelationData", None)
        key = correlation.decode("ascii", errors="replace") if correlation else ""
        fanout = self.pending.get(key)
        if fanout is None:
            self.counters.late += 1
            return
        if model_id not in self.specs or model_id in fanout.outcomes:
            self.counters.duplicate += 1
            return
        fanout.outcomes[model_id] = interpret(self.specs[model_id], payload)
        if fanout.complete:
            self._finish(fanout)

    def expire(self) -> None:
        """Finish every fan-out past its deadline."""
        now = self.clock()
        for fanout in [fanout for fanout in self.pending.values() if fanout.deadline <= now]:
            self._finish(fanout)

    def _finish(self, fanout: Fanout) -> None:
        self.pending.pop(fanout.correlation, None)
        response = aggregate(self.config, fanout, self.clock())
        setattr(self.counters, response["status"], getattr(self.counters, response["status"]) + 1)
        logger.info(
            "Ensemble %s: %s, decision %s (%d/%d succeeded)",
            self.config.ensemble_id,
            response["status"],
            response["decision"],
            response["counts"]["succeeded"],
            len(fanout.expected),
        )
        self._publish(
            self.config.response_topic(fanout.client),
            json.dumps(response, separators=(",", ":")).encode(),
            publish_properties(
                self.config, RESPONSE_TYPE, self.config.ensemble_id, fanout.request_correlation, fanout.traceparent
            ),
        )

    def _reject(
        self, client: str, req_id: str | None, correlation: bytes | None, traceparent: str | None, code: str
    ) -> None:
        self.counters.rejected += 1
        logger.warning("Rejected orchestration request: %s", code)
        body: dict = {
            "schema_version": "1.0",
            "ensemble_id": self.config.ensemble_id,
            "status": "rejected",
            "error": {"code": code, "retryable": code == "BUSY"},
        }
        if req_id:
            body["request_id"] = req_id
        self._publish(
            self.config.response_topic(client),
            json.dumps(body, separators=(",", ":")).encode(),
            publish_properties(self.config, RESPONSE_TYPE, self.config.ensemble_id, correlation, traceparent),
        )

    def _publish(self, topic: str, payload: bytes, properties: Properties) -> None:
        if not self.publish(topic, payload, properties):
            self.counters.publish_failed += 1


class Runtime:
    """Owns the paho client and drives the orchestrator."""

    def __init__(self, config: OrchestratorConfig) -> None:
        self.config = config
        self.connected = False
        self.client = mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id=config.client_id,
            protocol=mqtt.MQTTv5,
        )
        if config.use_tls:
            self.client.tls_set(ca_certs=config.ca_file)
        self.orchestrator = Orchestrator(config, self._publish)
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.message_callback_add(config.request_filter, self._on_request)
        self.client.message_callback_add(config.predict_response_filter, self._on_predict_response)

    def _publish(self, topic: str, payload: bytes, properties: Properties) -> bool:
        info = self.client.publish(topic, payload, qos=1, properties=properties)
        return info.rc == mqtt.MQTT_ERR_SUCCESS

    def connect_properties(self) -> Properties | None:
        """Return SAT enhanced-authentication properties, re-reading the token."""
        if not self.config.sat_file:
            return None
        with open(self.config.sat_file, encoding="utf-8") as handle:
            token = handle.read().strip()
        properties = Properties(PacketTypes.CONNECT)
        properties.AuthenticationMethod = SAT_AUTH_METHOD
        properties.AuthenticationData = token.encode()
        return properties

    def _on_connect(self, client, userdata, flags, reason_code, properties) -> None:
        if reason_code.is_failure:
            logger.error("Broker rejected connection: %s", reason_code)
            return
        self.connected = True
        self.orchestrator.counters.connects += 1
        client.subscribe(
            [(self.config.predict_response_filter, 1), (self.config.request_filter, 1)],
        )
        logger.info("Connected; serving %s", self.config.request_filter)

    def _on_disconnect(self, client, userdata, flags, reason_code, properties) -> None:
        self.connected = False
        logger.warning("Disconnected from broker: %s", reason_code)

    def _on_request(self, client, userdata, message: mqtt.MQTTMessage) -> None:
        self.orchestrator.handle_request(message.topic, message.payload, getattr(message, "properties", None))

    def _on_predict_response(self, client, userdata, message: mqtt.MQTTMessage) -> None:
        self.orchestrator.handle_predict_response(message.topic, message.payload, getattr(message, "properties", None))

    def log_counters(self, message: str) -> None:
        logger.info("%s: %s", message, json.dumps(asdict(self.orchestrator.counters)))


def run(config: OrchestratorConfig) -> None:
    """Run the orchestrator until SIGTERM or SIGINT."""
    runtime = Runtime(config)
    stopping = False

    def handle_signal(signum: int, frame: FrameType | None) -> None:
        nonlocal stopping
        logger.info("Received signal %s; shutting down", signum)
        stopping = True

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    logger.info("Ensemble %s: %s", config.ensemble_id, ",".join(model.id for model in config.models))

    reconnect_delay = INITIAL_RECONNECT_DELAY
    next_connect = 0.0
    next_counters = time.monotonic() + COUNTERS_INTERVAL_SECONDS
    socket_open = False

    while not stopping:
        now = time.monotonic()
        if not socket_open and now >= next_connect:
            try:
                runtime.client.connect(
                    config.broker_host, config.broker_port, keepalive=30, properties=runtime.connect_properties()
                )
                socket_open = True
            except OSError as error:
                logger.warning("Connection attempt failed (%s); retrying in %.0fs", error, reconnect_delay)
                next_connect = now + reconnect_delay
                reconnect_delay = min(reconnect_delay * 2, MAX_RECONNECT_DELAY)

        if socket_open:
            if runtime.client.loop(timeout=0.05) != mqtt.MQTT_ERR_SUCCESS:
                socket_open = False
                runtime.connected = False
                next_connect = time.monotonic() + reconnect_delay
                reconnect_delay = min(reconnect_delay * 2, MAX_RECONNECT_DELAY)
            elif runtime.connected:
                reconnect_delay = INITIAL_RECONNECT_DELAY
                runtime.orchestrator.expire()
        else:
            time.sleep(0.05)

        if time.monotonic() >= next_counters:
            runtime.log_counters("Counters")
            next_counters = time.monotonic() + COUNTERS_INTERVAL_SECONDS

    if socket_open and runtime.connected:
        runtime.client.disconnect()
        runtime.client.loop(timeout=0.5)
    runtime.log_counters("Stopped")


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    try:
        config = OrchestratorConfig.from_env()
    except (ValidationError, ValueError) as error:
        logger.error("Invalid configuration: %s", error)
        return 2
    run(config)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
