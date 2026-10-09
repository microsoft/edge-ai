"""Configuration and message contract for the MQTT predict adapter."""

from __future__ import annotations

import base64
import binascii
import json
import math
import os
import re
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator

CONTRACT_VERSION = "v1"
SCHEMA_VERSION = "1.0"
TOPIC_SEGMENT = re.compile(r"^[a-z0-9._-]{1,64}$")
MODEL_ID = re.compile(r"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$")
CONTENT_TYPE = re.compile(r"^[a-z]+/[a-z0-9.+-]+$")
MAX_REQUEST_ID_LEN = 256
MAX_CORRELATION_DATA_LEN = 256
MAX_CONTEXT_BYTES = 1024
MAX_TENSOR_DIMENSIONS = 4
RETRY_BACKOFF_SECONDS = 0.5


class AdapterConfig(BaseModel):
    """Validated runtime configuration."""

    model_config = ConfigDict(frozen=True)

    broker_host: str = "aio-broker.azure-iot-operations"
    broker_port: int = Field(default=18883, gt=0, le=65535)
    use_tls: bool = True
    ca_file: str | None = "/var/run/certs/ca.crt"
    sat_file: str | None = "/var/run/secrets/tokens/mq-sat"
    client_id: str = "predict-adapter"

    topic_domain: str = "predict"
    request_kind: str = "request"
    response_kind: str = "response"
    event_source: str = "predict-adapter"

    allowed_models: tuple[str, ...]
    endpoint_template: str = "https://{model_id}.foundry-local-operator.svc.cluster.local:5000/v1/predict"
    backend_auth_file: str | None = "/var/run/secrets/foundry-local/token"
    backend_ca_file: str | None = None
    backend_timeout_seconds: float = Field(default=30.0, gt=0, le=300)
    backend_attempts: int = Field(default=2, ge=1, le=5)

    max_request_bytes: int = Field(default=1024 * 1024, gt=0, le=16 * 1024 * 1024)
    max_response_bytes: int = Field(default=4 * 1024 * 1024, gt=0, le=64 * 1024 * 1024)
    max_concurrency: int = Field(default=4, ge=1, le=64)

    @model_validator(mode="after")
    def _validate(self) -> AdapterConfig:
        for name in ("topic_domain", "request_kind", "response_kind"):
            if not TOPIC_SEGMENT.match(getattr(self, name)):
                raise ValueError(f"{name} must be 1-64 lowercase letters, digits, '.', '_', or '-'")
        if self.request_kind == self.response_kind:
            raise ValueError("response_kind must differ from request_kind")
        if not self.allowed_models:
            raise ValueError("at least one allowed model is required")
        for model_id in self.allowed_models:
            if not MODEL_ID.match(model_id):
                raise ValueError(f"allowed model {model_id!r} must be a lowercase DNS label")
        if self.endpoint_template.count("{model_id}") != 1:
            raise ValueError("endpoint_template must contain {model_id} exactly once")
        if not self.endpoint_template.startswith(("https://", "http://")):
            raise ValueError("endpoint_template must be an http or https URL")
        if self.backend_auth_file and not self.endpoint_template.startswith("https://"):
            raise ValueError("backend_auth_file requires an https endpoint_template; set BACKEND_AUTH_FILE empty")
        if self.sat_file and not self.use_tls:
            raise ValueError("sat_file requires TLS to the broker; set AIO_SAT_FILE empty or enable AIO_MQTT_USE_TLS")
        if not self.client_id.strip():
            raise ValueError("client_id must not be empty")
        return self

    @property
    def max_request_seconds(self) -> float:
        """Return the longest a request can spend in backend attempts and retry backoff."""
        backoff = sum(RETRY_BACKOFF_SECONDS * 2**attempt for attempt in range(self.backend_attempts - 1))
        return self.backend_timeout_seconds * self.backend_attempts + backoff

    @property
    def request_filter(self) -> str:
        """Return the subscription filter for requests from any client."""
        return f"{self.topic_domain}/{CONTRACT_VERSION}/+/model/+/{self.request_kind}"

    def response_topic(self, client: str, model_id: str) -> str:
        """Return the response topic for a client and model."""
        return f"{self.topic_domain}/{CONTRACT_VERSION}/{client}/model/{model_id}/{self.response_kind}"

    def endpoint_for(self, model_id: str) -> str:
        """Return the backend URL for an allowed model."""
        return self.endpoint_template.replace("{model_id}", model_id)

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> AdapterConfig:
        """Build configuration from environment variables."""
        source = os.environ if env is None else env

        def value(name: str) -> str | None:
            raw = source.get(name)
            return raw.strip() if raw and raw.strip() else None

        overrides: dict[str, object] = {}

        def put(field: str, name: str, convert: Callable[[str], object] = str) -> None:
            raw = value(name)
            if raw is not None:
                try:
                    overrides[field] = convert(raw)
                except ValueError as error:
                    raise ValueError(f"{name} is invalid: {error}") from error

        put("broker_host", "AIO_BROKER_HOSTNAME")
        put("broker_port", "AIO_BROKER_TCP_PORT", int)
        put("use_tls", "AIO_MQTT_USE_TLS", _parse_bool)
        put("ca_file", "AIO_TLS_CA_FILE")
        put("sat_file", "AIO_SAT_FILE")
        put("client_id", "AIO_MQTT_CLIENT_ID")
        put("topic_domain", "TOPIC_DOMAIN")
        put("request_kind", "REQUEST_KIND")
        put("response_kind", "RESPONSE_KIND")
        put("event_source", "EVENT_SOURCE")
        put("allowed_models", "ALLOWED_MODELS", _parse_list)
        put("endpoint_template", "MODEL_ENDPOINT_TEMPLATE")
        put("backend_auth_file", "BACKEND_AUTH_FILE")
        put("backend_ca_file", "BACKEND_CA_FILE")
        put("backend_timeout_seconds", "BACKEND_TIMEOUT_SECONDS", float)
        put("backend_attempts", "BACKEND_ATTEMPTS", int)
        put("max_request_bytes", "MAX_REQUEST_BYTES", int)
        put("max_response_bytes", "MAX_RESPONSE_BYTES", int)
        put("max_concurrency", "MAX_CONCURRENCY", int)

        for name, field in (("AIO_SAT_FILE", "sat_file"), ("BACKEND_AUTH_FILE", "backend_auth_file")):
            if name in source and value(name) is None:
                overrides[field] = None
        if "allowed_models" not in overrides:
            raise ValueError("ALLOWED_MODELS must list at least one model ID")
        return cls(**overrides)


def _parse_bool(raw: str) -> bool:
    lowered = raw.lower()
    if lowered in ("1", "true", "yes", "on"):
        return True
    if lowered in ("0", "false", "no", "off"):
        return False
    raise ValueError(f"expected a boolean, got {raw!r}")


def _parse_list(raw: str) -> tuple[str, ...]:
    return tuple(dict.fromkeys(part.strip() for part in raw.split(",") if part.strip()))


class RequestError(Exception):
    """Request rejected before reaching the backend."""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


@dataclass(frozen=True)
class RequestTopic:
    """Client and model parsed from a request topic."""

    client: str
    model_id: str


@dataclass(frozen=True)
class PredictItem:
    """Single backend input item."""

    content_type: str
    data: bytes


@dataclass(frozen=True)
class PredictRequest:
    """Validated request: the backend item and the caller context to echo."""

    item: PredictItem
    context: dict[str, Any] | None = None


def parse_request_topic(config: AdapterConfig, topic: str) -> RequestTopic | None:
    """Return the client and model from a request topic, or None if it doesn't match."""
    parts = topic.split("/")
    if (
        len(parts) != 6
        or parts[0] != config.topic_domain
        or parts[1] != CONTRACT_VERSION
        or parts[3] != "model"
        or parts[5] != config.request_kind
    ):
        return None
    client, model_id = parts[2], parts[4]
    if not TOPIC_SEGMENT.match(client) or not TOPIC_SEGMENT.match(model_id):
        return None
    return RequestTopic(client=client, model_id=model_id)


def parse_request_payload(payload: bytes, max_bytes: int) -> PredictRequest:
    """Validate a request payload and return the backend item and caller context.

    Accepts either a numeric tensor in ``inputs`` (a flat list is wrapped into
    one row) or Base64 ``data`` with an explicit ``content_type``. An optional
    ``context`` object is echoed on the response and never sent to the model.
    """
    if len(payload) > max_bytes:
        raise RequestError("PAYLOAD_TOO_LARGE", f"request exceeds {max_bytes} bytes")
    try:
        body = load_json(payload)
    except ValueError as error:
        raise RequestError("INVALID_JSON", "request is not valid JSON with finite numbers") from error
    if not isinstance(body, dict):
        raise RequestError("INVALID_PAYLOAD", "request must be a JSON object")

    context = body.get("context")
    if context is not None and not _is_bounded_object(context, MAX_CONTEXT_BYTES):
        raise RequestError("INVALID_PAYLOAD", f"context must be an object of at most {MAX_CONTEXT_BYTES} bytes")

    has_inputs = "inputs" in body
    has_data = "data" in body
    if has_inputs == has_data:
        raise RequestError("INVALID_PAYLOAD", "request must contain exactly one of inputs or data")

    if has_inputs:
        inputs = body["inputs"]
        if not isinstance(inputs, list) or not inputs:
            raise RequestError("INVALID_PAYLOAD", "inputs must be a non-empty list")
        tensor = inputs if isinstance(inputs[0], list) else [inputs]
        if tensor_shape(tensor) is None:
            message = f"inputs must be a rectangular numeric tensor of up to {MAX_TENSOR_DIMENSIONS} dimensions"
            raise RequestError("INVALID_PAYLOAD", message)
        item = PredictItem("application/json", json.dumps(tensor, separators=(",", ":")).encode())
        return PredictRequest(item, context)

    content_type = body.get("content_type")
    if not isinstance(content_type, str) or not CONTENT_TYPE.match(content_type):
        raise RequestError("INVALID_PAYLOAD", "data requires a content_type such as image/jpeg")
    data = body["data"]
    if not isinstance(data, str) or not data:
        raise RequestError("INVALID_PAYLOAD", "data must be a non-empty Base64 string")
    try:
        decoded = base64.b64decode(data, validate=True)
    except (binascii.Error, ValueError) as error:
        raise RequestError("INVALID_PAYLOAD", "data must be standard Base64") from error
    return PredictRequest(PredictItem(content_type, decoded), context)


def _reject_constant(name: str) -> Any:
    raise ValueError(f"{name} is not a finite number")


def _finite_float(raw: str) -> float:
    value = float(raw)
    if not math.isfinite(value):
        raise ValueError("number is not finite")
    return value


def load_json(raw: bytes | str) -> Any:
    """Parse JSON, rejecting non-finite numbers and nesting too deep to decode.

    Raises ValueError for every rejection, including RecursionError from
    deeply nested input.
    """
    try:
        return json.loads(raw, parse_constant=_reject_constant, parse_float=_finite_float)
    except RecursionError as error:
        raise ValueError("JSON nesting is too deep") from error


def _is_bounded_object(value: Any, max_bytes: int) -> bool:
    if not isinstance(value, dict):
        return False
    try:
        return len(json.dumps(value, separators=(",", ":")).encode()) <= max_bytes
    except (RecursionError, ValueError):
        return False


def tensor_shape(value: Any, depth: int = 0) -> tuple[int, ...] | None:
    """Return the shape of a rectangular tensor of finite numbers, or None."""
    if isinstance(value, list):
        if not value or depth >= MAX_TENSOR_DIMENSIONS:
            return None
        first = tensor_shape(value[0], depth + 1)
        if first is None or any(tensor_shape(item, depth + 1) != first for item in value[1:]):
            return None
        return (len(value), *first)
    if isinstance(value, bool) or not isinstance(value, int | float):
        return None
    if isinstance(value, float) and not math.isfinite(value):
        return None
    return ()


def build_predict_body(item: PredictItem) -> dict[str, Any]:
    """Return the Foundry Local ``/v1/predict`` request body for an item."""
    return {
        "items": [
            {
                "content_type": item.content_type,
                "encoder": "base64",
                "data": base64.b64encode(item.data).decode("ascii"),
            }
        ]
    }


def decode_predict_response(body: Any) -> Any:
    """Return model outputs from a ``/v1/predict`` response body.

    JSON items are decoded; other content types are returned as Base64 with
    their content type. Raises ValueError when items[0] isn't a decodable object.
    """
    try:
        item = body["items"][0]
        if not isinstance(item, dict):
            raise TypeError("items[0] is not an object")
        content_type = item.get("content_type", "application/json")
        if not isinstance(content_type, str):
            raise TypeError("content_type is not a string")
        raw = base64.b64decode(item["data"], validate=True)
    except (KeyError, IndexError, TypeError, binascii.Error, ValueError) as error:
        raise ValueError("backend response has no decodable items[0]") from error
    if content_type == "application/json":
        return load_json(raw)
    return {"content_type": content_type, "data": base64.b64encode(raw).decode("ascii")}


class PredictResponse(BaseModel):
    """Response payload published for every handled request."""

    schema_version: str = SCHEMA_VERSION
    model_id: str
    request_id: str | None = None
    status: str
    latency_ms: int
    outputs: Any = None
    error: dict[str, Any] | None = None
    context: dict[str, Any] | None = None


def request_id(user_properties: list[tuple[str, str]]) -> str | None:
    """Return the request's CloudEvents ``id`` when present and bounded."""
    for key, value in user_properties:
        if key == "id" and 0 < len(value) <= MAX_REQUEST_ID_LEN:
            return value
    return None
