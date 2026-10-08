#!/usr/bin/env python3
"""MQTT predict adapter for Azure IoT Operations.

Subscribes to versioned predict request topics, calls a predictive model
endpoint such as a Foundry Local ``/v1/predict`` deployment, and publishes
each result to the requesting client's response topic.
"""

from __future__ import annotations

import json
import logging
import queue
import re
import signal
import time
import uuid
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from types import FrameType

import httpx
import paho.mqtt.client as mqtt
from models import (
    MAX_CORRELATION_DATA_LEN,
    AdapterConfig,
    PredictItem,
    PredictRequest,
    PredictResponse,
    RequestError,
    build_predict_body,
    decode_predict_response,
    parse_request_payload,
    parse_request_topic,
    request_id,
)
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties
from pydantic import ValidationError

logger = logging.getLogger("predict-adapter")

SAT_AUTH_METHOD = "K8S-SAT"
CONTENT_TYPE = "application/json"
RESPONSE_TYPE = "edge-ai.predict.response"
TRACEPARENT = re.compile(r"^00-(?!0{32})[0-9a-f]{32}-(?!0{16})[0-9a-f]{16}-[0-9a-f]{2}$")
RETRYABLE_STATUS = {429, 502, 503, 504}
INITIAL_RECONNECT_DELAY = 1.0
MAX_RECONNECT_DELAY = 30.0
COUNTERS_INTERVAL_SECONDS = 60.0


class BackendError(Exception):
    """Backend call failure mapped to a stable error code."""

    def __init__(self, code: str, retryable: bool, status: int | None = None) -> None:
        super().__init__(code)
        self.code = code
        self.retryable = retryable
        self.status = status


class PredictBackend:
    """Calls a predictive model endpoint over HTTP."""

    def __init__(
        self,
        config: AdapterConfig,
        client: httpx.Client | None = None,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._config = config
        self._client = client or httpx.Client(
            timeout=config.backend_timeout_seconds,
            verify=config.backend_ca_file or True,
        )
        self._sleep = sleep

    def predict(self, model_id: str, item: PredictItem) -> object:
        """Return decoded model outputs, retrying transient failures."""
        url = self._config.endpoint_for(model_id)
        body = build_predict_body(item)
        delay = 0.5
        for attempt in range(1, self._config.backend_attempts + 1):
            try:
                return self._call(url, body)
            except BackendError as error:
                if not error.retryable or attempt == self._config.backend_attempts:
                    raise
            self._sleep(delay)
            delay *= 2
        raise BackendError("BACKEND_UNAVAILABLE", retryable=True)

    def _call(self, url: str, body: dict) -> object:
        try:
            response = self._client.post(url, json=body, headers=self._headers())
        except httpx.TimeoutException as error:
            raise BackendError("BACKEND_TIMEOUT", retryable=True) from error
        except httpx.TransportError as error:
            raise BackendError("BACKEND_UNAVAILABLE", retryable=True) from error
        if response.status_code in (401, 403):
            raise BackendError("BACKEND_UNAUTHORIZED", retryable=False, status=response.status_code)
        if response.status_code == 404:
            raise BackendError("MODEL_UNAVAILABLE", retryable=False, status=404)
        if response.status_code in RETRYABLE_STATUS:
            raise BackendError("BACKEND_UNAVAILABLE", retryable=True, status=response.status_code)
        if response.status_code >= 400:
            raise BackendError("BACKEND_REJECTED", retryable=False, status=response.status_code)
        try:
            return decode_predict_response(response.json())
        except ValueError as error:
            raise BackendError("BACKEND_INVALID_RESPONSE", retryable=False) from error

    def _headers(self) -> dict[str, str]:
        headers = {"Content-Type": CONTENT_TYPE}
        if self._config.backend_auth_file:
            with open(self._config.backend_auth_file, encoding="utf-8") as handle:
                headers["Authorization"] = f"Bearer {handle.read().strip()}"
        return headers


@dataclass
class Counters:
    """Fixed-cardinality counters logged periodically."""

    received: int = 0
    succeeded: int = 0
    failed: int = 0
    rejected: int = 0
    busy: int = 0
    publish_failed: int = 0
    connects: int = 0
    by_error: dict[str, int] = field(default_factory=dict)

    def record_error(self, code: str) -> None:
        self.by_error[code] = self.by_error.get(code, 0) + 1


@dataclass(frozen=True)
class Outgoing:
    """Response ready to publish from the MQTT thread."""

    topic: str
    payload: bytes
    properties: Properties
    error_code: str | None = None
    from_worker: bool = False


def _rfc3339(moment: datetime) -> str:
    return moment.astimezone(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def response_properties(
    config: AdapterConfig,
    model_id: str,
    correlation_data: bytes | None,
    traceparent: str | None,
) -> Properties:
    """Return MQTT v5 properties carrying CloudEvents attributes and request context."""
    properties = Properties(PacketTypes.PUBLISH)
    properties.ContentType = CONTENT_TYPE
    properties.PayloadFormatIndicator = 1
    attributes = [
        ("specversion", "1.0"),
        ("type", RESPONSE_TYPE),
        ("source", config.event_source),
        ("id", str(uuid.uuid4())),
        ("time", _rfc3339(datetime.now(UTC))),
        ("subject", model_id),
        ("datacontenttype", CONTENT_TYPE),
    ]
    if traceparent:
        attributes.append(("traceparent", traceparent))
    # paho appends on every UserProperty assignment, so assign exactly once.
    properties.UserProperty = attributes
    if correlation_data:
        properties.CorrelationData = correlation_data
    return properties


def request_context(properties: Properties | None) -> tuple[list[tuple[str, str]], bytes | None, str | None]:
    """Return user properties, bounded Correlation Data, and a valid traceparent."""
    user_properties: list[tuple[str, str]] = list(getattr(properties, "UserProperty", None) or [])
    correlation = getattr(properties, "CorrelationData", None)
    if correlation is not None and len(correlation) > MAX_CORRELATION_DATA_LEN:
        correlation = None
    traceparent = next(
        (value for key, value in user_properties if key == "traceparent" and TRACEPARENT.match(value)),
        None,
    )
    return user_properties, correlation, traceparent


def build_response(
    config: AdapterConfig,
    model_id: str,
    req_id: str | None,
    started: float,
    outputs: object = None,
    error: dict | None = None,
    context: dict | None = None,
) -> bytes:
    """Return the serialized response payload."""
    response = PredictResponse(
        model_id=model_id,
        request_id=req_id,
        status="error" if error else "success",
        latency_ms=round((time.monotonic() - started) * 1000),
        outputs=None if error else outputs,
        error=error,
        context=context,
    )
    return response.model_dump_json(exclude_none=True).encode()


def error_body(code: str, message: str, retryable: bool) -> dict:
    """Return a payload-safe error object."""
    return {"code": code, "message": message, "retryable": retryable}


class Adapter:
    """Owns the MQTT client; only the main thread touches it."""

    def __init__(self, config: AdapterConfig, backend: PredictBackend) -> None:
        self.config = config
        self.backend = backend
        self.counters = Counters()
        self.connected = False
        self.outgoing: queue.Queue[Outgoing] = queue.Queue()
        self.executor = ThreadPoolExecutor(max_workers=config.max_concurrency, thread_name_prefix="predict")
        self.in_flight = 0
        self.client = self._build_client()

    def _build_client(self) -> mqtt.Client:
        client = mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id=self.config.client_id,
            protocol=mqtt.MQTTv5,
        )
        if self.config.use_tls:
            client.tls_set(ca_certs=self.config.ca_file)
        client.on_connect = self._on_connect
        client.on_disconnect = self._on_disconnect
        client.on_message = self._on_message
        return client

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
        self.counters.connects += 1
        client.subscribe(self.config.request_filter, qos=1)
        logger.info("Connected; subscribed to %s", self.config.request_filter)

    def _on_disconnect(self, client, userdata, flags, reason_code, properties) -> None:
        self.connected = False
        logger.warning("Disconnected from broker: %s", reason_code)

    def _on_message(self, client, userdata, message: mqtt.MQTTMessage) -> None:
        self.handle(message.topic, message.payload, getattr(message, "properties", None))

    def handle(self, topic: str, payload: bytes, properties: Properties | None) -> None:
        """Validate a request and dispatch it to a worker or answer immediately."""
        started = time.monotonic()
        parsed = parse_request_topic(self.config, topic)
        if parsed is None:
            return
        self.counters.received += 1
        user_properties, correlation, traceparent = request_context(properties)
        req_id = request_id(user_properties)
        reply_topic = self.config.response_topic(parsed.client, parsed.model_id)
        reply_properties = response_properties(self.config, parsed.model_id, correlation, traceparent)

        def reject(code: str, message: str, retryable: bool, context: dict | None = None) -> None:
            self.counters.rejected += 1
            self.counters.record_error(code)
            logger.warning("Rejected request for model %s: %s", parsed.model_id, code)
            body = build_response(
                self.config,
                parsed.model_id,
                req_id,
                started,
                error=error_body(code, message, retryable),
                context=context,
            )
            self.outgoing.put(Outgoing(reply_topic, body, reply_properties))

        if parsed.model_id not in self.config.allowed_models:
            reject("UNKNOWN_MODEL", "model is not served by this adapter", False)
            return
        try:
            request = parse_request_payload(payload, self.config.max_request_bytes)
        except RequestError as error:
            reject(error.code, error.message, False)
            return
        if self.in_flight >= self.config.max_concurrency:
            self.counters.busy += 1
            reject("BUSY", "adapter is at its concurrency limit", True, request.context)
            return

        self.in_flight += 1
        self.executor.submit(self._predict, parsed.model_id, request, req_id, started, reply_topic, reply_properties)

    def _predict(
        self,
        model_id: str,
        request: PredictRequest,
        req_id: str | None,
        started: float,
        reply_topic: str,
        reply_properties: Properties,
    ) -> None:
        error_code: str | None = None
        context = request.context
        try:
            outputs = self.backend.predict(model_id, request.item)
            body = build_response(self.config, model_id, req_id, started, outputs=outputs, context=context)
        except BackendError as error:
            error_code = error.code
            body = build_response(
                self.config,
                model_id,
                req_id,
                started,
                error=error_body(error.code, "model endpoint call failed", error.retryable),
                context=context,
            )
        except Exception:  # noqa: BLE001
            error_code = "INTERNAL_ERROR"
            logger.exception("Unexpected failure calling model %s", model_id)
            body = build_response(
                self.config,
                model_id,
                req_id,
                started,
                error=error_body("INTERNAL_ERROR", "adapter failed to process the request", True),
                context=context,
            )
        self.outgoing.put(Outgoing(reply_topic, body, reply_properties, error_code, from_worker=True))

    def drain(self) -> None:
        """Publish completed responses from the MQTT thread."""
        while True:
            try:
                outgoing = self.outgoing.get_nowait()
            except queue.Empty:
                return
            if outgoing.from_worker:
                self.in_flight -= 1
                if outgoing.error_code is None:
                    self.counters.succeeded += 1
                else:
                    self.counters.failed += 1
                    self.counters.record_error(outgoing.error_code)
                    logger.warning("Model call failed: %s", outgoing.error_code)
            info = self.client.publish(outgoing.topic, outgoing.payload, qos=1, properties=outgoing.properties)
            if info.rc != mqtt.MQTT_ERR_SUCCESS:
                self.counters.publish_failed += 1

    def log_counters(self, message: str) -> None:
        logger.info("%s: %s", message, json.dumps(asdict(self.counters)))


def run(config: AdapterConfig) -> None:
    """Run the adapter until SIGTERM or SIGINT."""
    adapter = Adapter(config, PredictBackend(config))
    stopping = False

    def handle_signal(signum: int, frame: FrameType | None) -> None:
        nonlocal stopping
        logger.info("Received signal %s; shutting down", signum)
        stopping = True

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    logger.info("Serving models %s", ",".join(config.allowed_models))

    reconnect_delay = INITIAL_RECONNECT_DELAY
    next_connect = 0.0
    next_counters = time.monotonic() + COUNTERS_INTERVAL_SECONDS
    socket_open = False

    while not stopping:
        now = time.monotonic()
        if not socket_open and now >= next_connect:
            try:
                adapter.client.connect(
                    config.broker_host,
                    config.broker_port,
                    keepalive=30,
                    properties=adapter.connect_properties(),
                )
                socket_open = True
            except OSError as error:
                logger.warning("Connection attempt failed (%s); retrying in %.0fs", error, reconnect_delay)
                next_connect = now + reconnect_delay
                reconnect_delay = min(reconnect_delay * 2, MAX_RECONNECT_DELAY)

        if socket_open:
            if adapter.client.loop(timeout=0.05) != mqtt.MQTT_ERR_SUCCESS:
                socket_open = False
                adapter.connected = False
                next_connect = time.monotonic() + reconnect_delay
                reconnect_delay = min(reconnect_delay * 2, MAX_RECONNECT_DELAY)
            elif adapter.connected:
                reconnect_delay = INITIAL_RECONNECT_DELAY
                adapter.drain()
        else:
            time.sleep(0.05)

        if time.monotonic() >= next_counters:
            adapter.log_counters("Counters")
            next_counters = time.monotonic() + COUNTERS_INTERVAL_SECONDS

    adapter.executor.shutdown(wait=True, cancel_futures=True)
    if socket_open and adapter.connected:
        adapter.drain()
        adapter.client.loop(timeout=0.5)
        adapter.client.disconnect()
        adapter.client.loop(timeout=0.5)
    adapter.log_counters("Stopped")


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    logging.getLogger("httpx").setLevel(logging.WARNING)
    try:
        config = AdapterConfig.from_env()
    except (ValidationError, ValueError) as error:
        logger.error("Invalid configuration: %s", error)
        return 2
    run(config)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
