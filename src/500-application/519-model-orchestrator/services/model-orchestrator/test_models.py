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
    aggregate,
    interpret,
    parse_predict_response_topic,
    parse_request_topic,
    validate_request_body,
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
        [{"score": "0.9"}, {"score": True}, {"value": 0.9}, {"score": float("inf")}, [0.9], {"score": [0.9]}],
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

    @pytest.mark.parametrize("body", [b"not json", b"[]", b'{"status": "success"}', b'{"status": "pending"}'])
    def test_rejects_malformed_responses(self, body):
        assert interpret(self.score, body).status is ModelStatus.REJECTED


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
    ("payload", "code"),
    [(b'{"inputs": [1]}', None), (b'{"data": "AA=="}', None), (b"{}", "INVALID_PAYLOAD"), (b"x", "INVALID_JSON")],
)
def test_validate_request_body(payload, code):
    assert validate_request_body(payload, 1024) == code
    assert validate_request_body(payload, 0) == "PAYLOAD_TOO_LARGE"


def test_model_spec_rejects_unknown_kind():
    with pytest.raises(ValidationError):
        ModelSpec.model_validate({"id": "a", "result": {"kind": "numeric-leaves", "field": "x"}})
