"""Configuration, typed result adapters, and aggregation for the model orchestrator."""

from __future__ import annotations

import json
import math
import os
import re
from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Annotated, Any, Literal

from pydantic import BaseModel, ConfigDict, Field, TypeAdapter, model_validator

CONTRACT_VERSION = "v1"
SCHEMA_VERSION = "1.0"
TOPIC_SEGMENT = re.compile(r"^[a-z0-9._-]{1,64}$")
MODEL_ID = re.compile(r"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$")
FIELD_PATH = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,63}(\.[A-Za-z_][A-Za-z0-9_]{0,63}){0,3}$")
MAX_REQUEST_ID_LEN = 256
MAX_LABEL_LEN = 128


class ScoreAdapter(BaseModel):
    """Reads one finite number and flags an anomaly above a threshold."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    kind: Literal["score"]
    field: str
    threshold: float

    def evaluate(self, outputs: Any) -> ModelResult:
        value = _lookup(outputs, self.field)
        if isinstance(value, bool) or not isinstance(value, int | float) or not math.isfinite(value):
            raise ResultError("INVALID_RESULT")
        return ModelResult(score=float(value), anomaly=value > self.threshold)


class LabelAdapter(BaseModel):
    """Reads one label and flags an anomaly when it's in a configured set."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    kind: Literal["label"]
    field: str
    anomaly_labels: tuple[str, ...] = Field(min_length=1)
    score_field: str | None = None

    def evaluate(self, outputs: Any) -> ModelResult:
        label = _lookup(outputs, self.field)
        if not isinstance(label, str) or not 0 < len(label) <= MAX_LABEL_LEN:
            raise ResultError("INVALID_RESULT")
        score = None
        if self.score_field:
            value = _lookup(outputs, self.score_field)
            if isinstance(value, bool) or not isinstance(value, int | float) or not 0 <= value <= 1:
                raise ResultError("INVALID_RESULT")
            score = float(value)
        return ModelResult(label=label, score=score, anomaly=label in self.anomaly_labels)


ResultAdapter = Annotated[ScoreAdapter | LabelAdapter, Field(discriminator="kind")]


class ModelSpec(BaseModel):
    """One ensemble member and the adapter that interprets its outputs."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    id: str
    result: ResultAdapter

    @model_validator(mode="after")
    def _validate(self) -> ModelSpec:
        if not MODEL_ID.match(self.id):
            raise ValueError(f"model id {self.id!r} must be a lowercase DNS label")
        for path in (self.result.field, getattr(self.result, "score_field", None)):
            if path is not None and not FIELD_PATH.match(path):
                raise ValueError(f"field path {path!r} must be up to four dot-separated identifiers")
        return self


MODELS_ADAPTER = TypeAdapter(tuple[ModelSpec, ...])


class OrchestratorConfig(BaseModel):
    """Validated runtime configuration."""

    model_config = ConfigDict(frozen=True)

    broker_host: str = "aio-broker.azure-iot-operations"
    broker_port: int = Field(default=18883, gt=0, le=65535)
    use_tls: bool = True
    ca_file: str | None = "/var/run/certs/ca.crt"
    sat_file: str | None = "/var/run/secrets/tokens/mq-sat"
    client_id: str = "model-orchestrator"

    topic_domain: str = "orchestrate"
    ensemble_id: str = "default"
    predict_domain: str = "predict"
    predict_client: str = "model-orchestrator"
    event_source: str = "model-orchestrator"

    models: tuple[ModelSpec, ...]
    timeout_seconds: float = Field(default=10.0, gt=0, le=600)
    max_pending: int = Field(default=100, ge=1, le=10000)
    max_request_bytes: int = Field(default=1024 * 1024, gt=0, le=16 * 1024 * 1024)

    @model_validator(mode="after")
    def _validate(self) -> OrchestratorConfig:
        for name in ("topic_domain", "ensemble_id", "predict_domain", "predict_client"):
            if not TOPIC_SEGMENT.match(getattr(self, name)):
                raise ValueError(f"{name} must be 1-64 lowercase letters, digits, '.', '_', or '-'")
        if self.topic_domain == self.predict_domain:
            raise ValueError("predict_domain must differ from topic_domain")
        if not self.models:
            raise ValueError("at least one model is required")
        ids = [model.id for model in self.models]
        if len(ids) != len(set(ids)):
            raise ValueError("model ids must be unique")
        if not self.client_id.strip():
            raise ValueError("client_id must not be empty")
        return self

    @property
    def request_filter(self) -> str:
        return f"{self.topic_domain}/{CONTRACT_VERSION}/+/ensemble/{self.ensemble_id}/request"

    def response_topic(self, client: str) -> str:
        return f"{self.topic_domain}/{CONTRACT_VERSION}/{client}/ensemble/{self.ensemble_id}/response"

    def predict_request_topic(self, model_id: str) -> str:
        return f"{self.predict_domain}/{CONTRACT_VERSION}/{self.predict_client}/model/{model_id}/request"

    @property
    def predict_response_filter(self) -> str:
        return f"{self.predict_domain}/{CONTRACT_VERSION}/{self.predict_client}/model/+/response"

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> OrchestratorConfig:
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
        put("ensemble_id", "ENSEMBLE_ID")
        put("predict_domain", "PREDICT_DOMAIN")
        put("predict_client", "PREDICT_CLIENT")
        put("event_source", "EVENT_SOURCE")
        put("models", "MODELS", _parse_models)
        put("timeout_seconds", "TIMEOUT_SECONDS", float)
        put("max_pending", "MAX_PENDING", int)
        put("max_request_bytes", "MAX_REQUEST_BYTES", int)

        if "AIO_SAT_FILE" in source and value("AIO_SAT_FILE") is None:
            overrides["sat_file"] = None
        if "models" not in overrides:
            raise ValueError("MODELS must define at least one model")
        return cls(**overrides)


def _parse_bool(raw: str) -> bool:
    lowered = raw.lower()
    if lowered in ("1", "true", "yes", "on"):
        return True
    if lowered in ("0", "false", "no", "off"):
        return False
    raise ValueError(f"expected a boolean, got {raw!r}")


def _parse_models(raw: str) -> tuple[ModelSpec, ...]:
    try:
        return MODELS_ADAPTER.validate_json(raw)
    except ValueError as error:
        raise ValueError(f"expected a JSON list of models: {error}") from error


def _lookup(outputs: Any, path: str) -> Any:
    current = outputs
    for key in path.split("."):
        if not isinstance(current, dict) or key not in current:
            raise ResultError("INVALID_RESULT")
        current = current[key]
    return current


class ResultError(Exception):
    """A model response that can't be interpreted by its adapter."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True)
class ModelResult:
    """Normalized result from one typed adapter."""

    anomaly: bool
    score: float | None = None
    label: str | None = None


class ModelStatus(StrEnum):
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    TIMED_OUT = "timed_out"
    REJECTED = "rejected"


@dataclass
class ModelOutcome:
    """Terminal outcome for one model in a fan-out."""

    status: ModelStatus
    result: ModelResult | None = None
    error_code: str | None = None
    latency_ms: int | None = None


@dataclass
class Fanout:
    """Pending fan-out state for one orchestration request."""

    correlation: str
    client: str
    request_id: str | None
    request_correlation: bytes | None
    traceparent: str | None
    started: float
    deadline: float
    expected: tuple[str, ...]
    outcomes: dict[str, ModelOutcome] = field(default_factory=dict)

    @property
    def complete(self) -> bool:
        return len(self.outcomes) == len(self.expected)


def interpret(spec: ModelSpec, body: bytes) -> ModelOutcome:
    """Map one predict adapter response to a terminal model outcome."""
    try:
        response = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return ModelOutcome(ModelStatus.REJECTED, error_code="INVALID_RESPONSE")
    if not isinstance(response, dict):
        return ModelOutcome(ModelStatus.REJECTED, error_code="INVALID_RESPONSE")
    latency = response.get("latency_ms")
    latency_ms = latency if isinstance(latency, int) and not isinstance(latency, bool) and latency >= 0 else None
    if response.get("status") == "error":
        error = response.get("error")
        code = error.get("code") if isinstance(error, dict) else None
        if not isinstance(code, str) or not TOPIC_SEGMENT.match(code.lower()):
            code = "MODEL_ERROR"
        return ModelOutcome(ModelStatus.FAILED, error_code=code, latency_ms=latency_ms)
    if response.get("status") != "success" or "outputs" not in response:
        return ModelOutcome(ModelStatus.REJECTED, error_code="INVALID_RESPONSE", latency_ms=latency_ms)
    try:
        result = spec.result.evaluate(response["outputs"])
    except ResultError as error:
        return ModelOutcome(ModelStatus.REJECTED, error_code=error.code, latency_ms=latency_ms)
    return ModelOutcome(ModelStatus.SUCCEEDED, result=result, latency_ms=latency_ms)


def aggregate(config: OrchestratorConfig, fanout: Fanout, now: float) -> dict[str, Any]:
    """Return the terminal aggregate response for a fan-out.

    Models without an outcome are reported as timed out. A timed-out or failed
    model never erases successful results from other models.
    """
    models = []
    counts = {status.value: 0 for status in ModelStatus}
    any_anomaly = False
    scores: list[float] = []
    for model_id in fanout.expected:
        outcome = fanout.outcomes.get(model_id, ModelOutcome(ModelStatus.TIMED_OUT, error_code="TIMEOUT"))
        counts[outcome.status.value] += 1
        entry: dict[str, Any] = {"model_id": model_id, "status": outcome.status.value}
        if outcome.result is not None:
            entry["anomaly"] = outcome.result.anomaly
            any_anomaly = any_anomaly or outcome.result.anomaly
            if outcome.result.score is not None:
                entry["score"] = outcome.result.score
                scores.append(outcome.result.score)
            if outcome.result.label is not None:
                entry["label"] = outcome.result.label
        if outcome.error_code:
            entry["error_code"] = outcome.error_code
        if outcome.latency_ms is not None:
            entry["latency_ms"] = outcome.latency_ms
        models.append(entry)

    succeeded = counts[ModelStatus.SUCCEEDED.value]
    if succeeded == len(fanout.expected):
        status = "complete"
    elif succeeded:
        status = "partial"
    else:
        status = "failed"
    if any_anomaly:
        decision = "anomaly"
    elif status == "complete":
        decision = "normal"
    else:
        decision = "unknown"

    response: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "ensemble_id": config.ensemble_id,
        "status": status,
        "decision": decision,
        "counts": counts,
        "duration_ms": round((now - fanout.started) * 1000),
        "models": models,
    }
    if fanout.request_id:
        response["request_id"] = fanout.request_id
    if scores:
        response["max_score"] = max(scores)
    return response


def request_id(user_properties: list[tuple[str, str]]) -> str | None:
    """Return the request's CloudEvents ``id`` when present and bounded."""
    for key, value in user_properties:
        if key == "id" and 0 < len(value) <= MAX_REQUEST_ID_LEN:
            return value
    return None


def parse_request_topic(config: OrchestratorConfig, topic: str) -> str | None:
    """Return the client segment of a request topic, or None when it doesn't match."""
    parts = topic.split("/")
    if (
        len(parts) != 6
        or parts[0] != config.topic_domain
        or parts[1] != CONTRACT_VERSION
        or parts[3] != "ensemble"
        or parts[4] != config.ensemble_id
        or parts[5] != "request"
        or not TOPIC_SEGMENT.match(parts[2])
    ):
        return None
    return parts[2]


def parse_predict_response_topic(config: OrchestratorConfig, topic: str) -> str | None:
    """Return the model ID of a predict response topic addressed to this orchestrator."""
    parts = topic.split("/")
    if (
        len(parts) != 6
        or parts[0] != config.predict_domain
        or parts[1] != CONTRACT_VERSION
        or parts[2] != config.predict_client
        or parts[3] != "model"
        or parts[5] != "response"
    ):
        return None
    return parts[4]


def validate_request_body(payload: bytes, max_bytes: int) -> str | None:
    """Return an error code when the request can't be forwarded, else None."""
    if len(payload) > max_bytes:
        return "PAYLOAD_TOO_LARGE"
    try:
        body = json.loads(payload)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return "INVALID_JSON"
    if not isinstance(body, dict) or ("inputs" in body) == ("data" in body):
        return "INVALID_PAYLOAD"
    return None
