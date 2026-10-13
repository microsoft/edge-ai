"""Unit tests for orchestrator configuration, result adapters, and aggregation."""

import json

import pytest
from models import (
    Fanout,
    ModelOutcome,
    ModelResult,
    ModelSpec,
    ModelStatus,
    OrchestratorConfig,
    RequestError,
    aggregate,
    interpret,
    parse_predict_response_topic,
    parse_request_body,
    parse_request_topic,
    tensor_shape,
)
from pydantic import ValidationError

MODELS = json.dumps(
    [
        {"id": "vibration-anomaly", "result": {"kind": "score", "field": "score", "threshold": 0.8}},
        {
            "id": "acoustic-classifier",
            "result": {
                "kind": "label",
                "field": "prediction.label",
                "anomaly_labels": ["fault"],
                "score_field": "prediction.confidence",
            },
        },
    ]
)


def config(**overrides) -> OrchestratorConfig:
    return OrchestratorConfig.from_env({"MODELS": MODELS, **overrides})


def response(outputs) -> bytes:
    return json.dumps({"status": "success", "latency_ms": 7, "outputs": outputs}).encode()


class TestConfig:
    def test_topics(self):
        cfg = config()
        assert cfg.request_filter == "orchestrate/v1/+/ensemble/default/request"
        assert cfg.response_topic("client-a") == "orchestrate/v1/client-a/ensemble/default/response"
        assert cfg.predict_request_topic("vibration-anomaly") == (
            "predict/v1/model-orchestrator/model/vibration-anomaly/request"
        )
        assert cfg.predict_response_filter == "predict/v1/model-orchestrator/model/+/response"

    def test_requires_models(self):
        with pytest.raises(ValueError, match="MODELS"):
            OrchestratorConfig.from_env({})

    @pytest.mark.parametrize(
        "models",
        [
            "not json",
            "[]",
            '[{"id": "Bad", "result": {"kind": "score", "field": "s", "threshold": 1}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "a..b", "threshold": 1}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "s"}}]',
            '[{"id": "a", "result": {"kind": "label", "field": "l", "anomaly_labels": []}}]',
            '[{"id": "a", "result": {"kind": "regex", "field": "s"}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "s", "threshold": 1, "extra": 1}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "s", "threshold": NaN}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "s", "threshold": "inf"}}]',
            '[{"id": "a", "result": {"kind": "score", "field": "s", "threshold": 1e999}}]',
        ],
    )
    def test_rejects_invalid_models(self, models):
        with pytest.raises((ValueError, ValidationError)):
            OrchestratorConfig.from_env({"MODELS": models})

    def test_rejects_duplicate_models(self):
        spec = '{"id": "a", "result": {"kind": "score", "field": "s", "threshold": 1}}'
        with pytest.raises(ValidationError, match="unique"):
            OrchestratorConfig.from_env({"MODELS": f"[{spec}, {spec}]"})

    def test_predict_domain_must_differ(self):
        with pytest.raises(ValidationError, match="predict_domain"):
            config(PREDICT_DOMAIN="orchestrate")

    def test_predict_kinds_are_configurable(self):
        cfg = config(PREDICT_REQUEST_KIND="req", PREDICT_RESPONSE_KIND="resp")
        assert cfg.predict_request_topic("m") == "predict/v1/model-orchestrator/model/m/req"
        assert cfg.predict_response_filter == "predict/v1/model-orchestrator/model/+/resp"
        assert parse_predict_response_topic(cfg, "predict/v1/model-orchestrator/model/m/resp") == "m"
        assert parse_predict_response_topic(cfg, "predict/v1/model-orchestrator/model/m/response") is None
        with pytest.raises(ValidationError, match="predict_response_kind"):
            config(PREDICT_RESPONSE_KIND="request")

    def test_rejects_broker_token_without_tls(self):
        with pytest.raises(ValidationError, match="TLS"):
            config(AIO_MQTT_USE_TLS="false")
        assert config(AIO_MQTT_USE_TLS="false", AIO_SAT_FILE="").sat_file is None

    def test_inflight_model_calls_default_and_bounds(self):
        assert config().max_inflight_model_calls == 4
        with pytest.raises(ValidationError):
            config(MAX_INFLIGHT_MODEL_CALLS="0")


class TestTopics:
    def test_parses_request_client(self):
        assert parse_request_topic(config(), "orchestrate/v1/client-a/ensemble/default/request") == "client-a"
        assert parse_request_topic(config(), "orchestrate/v1/client-a/ensemble/other/request") is None
        assert parse_request_topic(config(), "orchestrate/v1/client-a/ensemble/default/response") is None

    def test_parses_only_own_predict_responses(self):
        cfg = config()
        assert parse_predict_response_topic(cfg, "predict/v1/model-orchestrator/model/m/response") == "m"
        assert parse_predict_response_topic(cfg, "predict/v1/someone-else/model/m/response") is None


class TestInterpret:
    def setup_method(self):
        cfg = config()
        self.score, self.label = cfg.models

    def test_score_adapter(self):
        outcome = interpret(self.score, response({"score": 0.9}))
        assert outcome.status is ModelStatus.SUCCEEDED
        assert outcome.result == ModelResult(anomaly=True, score=0.9)
        assert outcome.latency_ms == 7
        assert interpret(self.score, response({"score": 0.5})).result.anomaly is False

    def test_label_adapter(self):
        outcome = interpret(self.label, response({"prediction": {"label": "fault", "confidence": 0.7}}))
        assert outcome.result == ModelResult(anomaly=True, score=0.7, label="fault")

    @pytest.mark.parametrize(
        "outputs",
        [{"score": "0.9"}, {"score": True}, {"value": 0.9}, [0.9], {"score": [0.9]}],
    )
    def test_never_searches_for_numbers(self, outputs):
        outcome = interpret(self.score, response(outputs))
        assert outcome.status is ModelStatus.REJECTED
        assert outcome.error_code == "INVALID_RESULT"

    def test_rejects_out_of_range_confidence(self):
        outcome = interpret(self.label, response({"prediction": {"label": "ok", "confidence": 1.5}}))
        assert outcome.status is ModelStatus.REJECTED

    def test_maps_adapter_errors(self):
        body = json.dumps({"status": "error", "error": {"code": "BACKEND_TIMEOUT"}}).encode()
        outcome = interpret(self.score, body)
        assert (outcome.status, outcome.error_code) == (ModelStatus.FAILED, "BACKEND_TIMEOUT")

    @pytest.mark.parametrize(
        "body",
        [
            b"not json",
            b"[]",
            b'{"status": "success"}',
            b'{"status": "pending"}',
            b"[" * 100_000 + b"]" * 100_000,
            b'{"status": "success", "outputs": {"score": NaN}}',
        ],
        ids=["text", "list", "no-outputs", "pending", "nested", "nan"],
    )
    def test_rejects_malformed_responses(self, body):
        assert interpret(self.score, body).status is ModelStatus.REJECTED

    def test_keeps_adapter_retryable_flag(self):
        body = json.dumps({"status": "error", "error": {"code": "BUSY", "retryable": True}}).encode()
        assert interpret(self.score, body).retryable is True
        body = json.dumps({"status": "error", "error": {"code": "BACKEND_REJECTED", "retryable": False}}).encode()
        assert interpret(self.score, body).retryable is False


class TestAggregate:
    def fanout(self, **outcomes) -> Fanout:
        fanout = Fanout("c", "client-a", "req-1", None, None, 0.0, 10.0, ("vibration-anomaly", "acoustic-classifier"))
        fanout.outcomes.update(outcomes)
        return fanout

    def test_complete_normal(self):
        result = aggregate(
            config(),
            self.fanout(
                **{
                    "vibration-anomaly": ModelOutcome(ModelStatus.SUCCEEDED, ModelResult(False, 0.2)),
                    "acoustic-classifier": ModelOutcome(ModelStatus.SUCCEEDED, ModelResult(False, 0.9, "ok")),
                }
            ),
            1.5,
        )
        assert (result["status"], result["decision"]) == ("complete", "normal")
        assert result["max_score"] == 0.9
        assert result["duration_ms"] == 1500
        assert result["request_id"] == "req-1"
        assert result["retryable"] is False

    def test_partial_keeps_successful_anomaly(self):
        result = aggregate(
            config(),
            self.fanout(**{"vibration-anomaly": ModelOutcome(ModelStatus.SUCCEEDED, ModelResult(True, 0.95))}),
            10.0,
        )
        assert (result["status"], result["decision"]) == ("partial", "anomaly")
        assert result["counts"] == {"succeeded": 1, "failed": 0, "timed_out": 1, "rejected": 0}
        assert result["models"][1] == {
            "model_id": "acoustic-classifier",
            "status": "timed_out",
            "error_code": "TIMEOUT",
        }
        assert result["retryable"] is True

    def test_retryable_only_for_retryable_failures(self):
        fanout = self.fanout(
            **{
                "vibration-anomaly": ModelOutcome(ModelStatus.SUCCEEDED, ModelResult(False, 0.1)),
                "acoustic-classifier": ModelOutcome(ModelStatus.REJECTED, error_code="INVALID_RESULT"),
            }
        )
        assert aggregate(config(), fanout, 1.0)["retryable"] is False
        fanout.outcomes["acoustic-classifier"] = ModelOutcome(ModelStatus.FAILED, error_code="BUSY", retryable=True)
        fanout.context = {"asset_id": "a-1"}
        result = aggregate(config(), fanout, 1.0)
        assert (result["retryable"], result["context"]) == (True, {"asset_id": "a-1"})

    def test_partial_without_anomaly_is_unknown(self):
        result = aggregate(
            config(),
            self.fanout(
                **{
                    "vibration-anomaly": ModelOutcome(ModelStatus.SUCCEEDED, ModelResult(False, 0.1)),
                    "acoustic-classifier": ModelOutcome(ModelStatus.FAILED, error_code="BACKEND_UNAVAILABLE"),
                }
            ),
            1.0,
        )
        assert (result["status"], result["decision"]) == ("partial", "unknown")

    def test_failed_when_nothing_succeeds(self):
        result = aggregate(config(), self.fanout(), 10.0)
        assert (result["status"], result["decision"]) == ("failed", "unknown")
        assert "max_score" not in result


@pytest.mark.parametrize(
    "payload",
    [
        b'{"inputs": [1]}',
        b'{"inputs": [[1, 2], [3, 4]]}',
        b'{"data": "AA==", "content_type": "image/jpeg"}',
    ],
)
def test_parse_request_body_accepts_adapter_forms(payload):
    assert parse_request_body(payload, 1024) is None
    with pytest.raises(RequestError, match="PAYLOAD_TOO_LARGE"):
        parse_request_body(payload, 0)


@pytest.mark.parametrize(
    ("payload", "code"),
    [
        (b"x", "INVALID_JSON"),
        (b"[" * 100_000 + b"]" * 100_000, "INVALID_JSON"),
        (b'{"inputs": [NaN]}', "INVALID_JSON"),
        (b'{"inputs": [1e999]}', "INVALID_JSON"),
        (b"{}", "INVALID_PAYLOAD"),
        (b"[1]", "INVALID_PAYLOAD"),
        (b'{"inputs": 1}', "INVALID_PAYLOAD"),
        (b'{"inputs": []}', "INVALID_PAYLOAD"),
        (b'{"inputs": ["a"]}', "INVALID_PAYLOAD"),
        (b'{"inputs": [true]}', "INVALID_PAYLOAD"),
        (b'{"inputs": [[1, 2], [3]]}', "INVALID_PAYLOAD"),
        (b'{"inputs": [[[[[[1]]]]]]}', "INVALID_PAYLOAD"),
        (b'{"data": "AA=="}', "INVALID_PAYLOAD"),
        (b'{"data": "%%", "content_type": "image/jpeg"}', "INVALID_PAYLOAD"),
    ],
    ids=lambda value: value[:24] if isinstance(value, bytes) else value,
)
def test_parse_request_body_rejects(payload, code):
    with pytest.raises(RequestError) as raised:
        parse_request_body(payload, 1024 * 1024)
    assert raised.value.code == code


def test_parse_request_body_validates_and_returns_context():
    assert parse_request_body(b'{"inputs": [1], "context": {"asset_id": "a-1"}}', 1024) == {"asset_id": "a-1"}
    for context in (b'"a-1"', b"[1]", json.dumps({"k": "x" * 1100}).encode()):
        with pytest.raises(RequestError) as raised:
            parse_request_body(b'{"inputs": [1], "context": ' + context + b"}", 4096)
        assert (raised.value.code, raised.value.context) == ("INVALID_PAYLOAD", None)
    with pytest.raises(RequestError) as raised:
        parse_request_body(b'{"inputs": ["a"], "context": {"asset_id": "a-1"}}', 1024)
    assert raised.value.context == {"asset_id": "a-1"}


@pytest.mark.parametrize(
    ("value", "shape"),
    [([[1, 2], [3, 4]], (2, 2)), ([[[1.5]]], (1, 1, 1)), ([[1], [2, 3]], None), ([[[[[1]]]]], None), ([[]], None)],
)
def test_tensor_shape(value, shape):
    assert tensor_shape(value) == shape


def test_model_spec_rejects_unknown_kind():
    with pytest.raises(ValidationError):
        ModelSpec.model_validate({"id": "a", "result": {"kind": "numeric-leaves", "field": "x"}})
