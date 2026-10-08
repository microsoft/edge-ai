"""Unit tests for the orchestration state machine."""

import json

from app import Orchestrator
from models import OrchestratorConfig
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties

MODELS = json.dumps(
    [
        {"id": "model-a", "result": {"kind": "score", "field": "score", "threshold": 0.5}},
        {"id": "model-b", "result": {"kind": "score", "field": "score", "threshold": 0.5}},
    ]
)
REQUEST = "orchestrate/v1/client-a/ensemble/default/request"
RESPONSE = "orchestrate/v1/client-a/ensemble/default/response"
TRACEPARENT = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"


class Clock:
    def __init__(self):
        self.now = 100.0

    def __call__(self):
        return self.now


def make(**env):
    published = []
    clock = Clock()

    def publish(topic, payload, properties):
        published.append((topic, payload, properties))
        return True

    orchestrator = Orchestrator(OrchestratorConfig.from_env({"MODELS": MODELS, **env}), publish, clock)
    return orchestrator, published, clock


def props(correlation: bytes | None = None, **user) -> Properties:
    properties = Properties(PacketTypes.PUBLISH)
    if user:
        properties.UserProperty = list(user.items())
    if correlation is not None:
        properties.CorrelationData = correlation
    return properties


def answer(orchestrator, published, model_id, score, index=None):
    topic, _, properties = next(
        item for item in published if item[0] == f"predict/v1/model-orchestrator/model/{model_id}/request"
    )
    body = json.dumps({"status": "success", "latency_ms": 3, "outputs": {"score": score}}).encode()
    orchestrator.handle_predict_response(
        topic.replace("/request", "/response"), body, props(properties.CorrelationData)
    )


def final(published):
    topic, payload, properties = published[-1]
    assert topic == RESPONSE
    return json.loads(payload), properties


def test_fans_out_with_correlation_and_trace_context():
    orchestrator, published, _ = make()
    orchestrator.handle_request(
        REQUEST, b'{"inputs": [1, 2]}', props(b"client-corr", id="req-1", traceparent=TRACEPARENT)
    )
    assert [item[0] for item in published] == [
        "predict/v1/model-orchestrator/model/model-a/request",
        "predict/v1/model-orchestrator/model/model-b/request",
    ]
    _, payload, properties = published[0]
    assert payload == b'{"inputs": [1, 2]}'
    assert properties.CorrelationData == published[1][2].CorrelationData
    attributes = dict(properties.UserProperty)
    assert attributes["traceparent"] == TRACEPARENT
    assert attributes["type"] == "edge-ai.predict.request"
    assert len(properties.UserProperty) == len(attributes)


def test_publishes_complete_aggregate_and_echoes_request_context():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(b"client-corr", id="req-1", traceparent=TRACEPARENT))
    answer(orchestrator, published, "model-a", 0.2)
    answer(orchestrator, published, "model-b", 0.9)
    body, properties = final(published)
    assert (body["status"], body["decision"], body["request_id"]) == ("complete", "anomaly", "req-1")
    assert properties.CorrelationData == b"client-corr"
    assert dict(properties.UserProperty)["traceparent"] == TRACEPARENT
    assert orchestrator.pending == {}
    assert orchestrator.counters.complete == 1


def test_timeout_produces_partial_result_and_late_answers_are_counted():
    orchestrator, published, clock = make(TIMEOUT_SECONDS="5")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    answer(orchestrator, published, "model-a", 0.1)
    clock.now += 5
    orchestrator.expire()
    body, _ = final(published)
    assert (body["status"], body["decision"]) == ("partial", "unknown")
    answer(orchestrator, published, "model-b", 0.9)
    assert orchestrator.counters.late == 1
    assert len([item for item in published if item[0] == RESPONSE]) == 1


def test_duplicate_model_answer_does_not_overwrite():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    answer(orchestrator, published, "model-a", 0.1)
    answer(orchestrator, published, "model-a", 0.9)
    assert orchestrator.counters.duplicate == 1
    answer(orchestrator, published, "model-b", 0.1)
    body, _ = final(published)
    assert body["decision"] == "normal"


def test_rejects_invalid_busy_and_duplicate_requests():
    orchestrator, published, _ = make(MAX_PENDING="1")
    orchestrator.handle_request(REQUEST, b"{}", props())
    assert final(published)[0]["error"]["code"] == "INVALID_PAYLOAD"

    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-1"))
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-2"))
    body = final(published)[0]
    assert body["error"] == {"code": "BUSY", "retryable": True}
    assert body["request_id"] == "req-2"

    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-1"))
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-1"))
    assert final(published)[0]["error"]["code"] == "DUPLICATE_REQUEST"
    assert orchestrator.counters.rejected == 1


def test_ignores_responses_for_other_clients_and_unknown_correlation():
    orchestrator, published, _ = make()
    orchestrator.handle_predict_response("predict/v1/someone-else/model/model-a/response", b"{}", props(b"x"))
    orchestrator.handle_predict_response(
        "predict/v1/model-orchestrator/model/model-a/response", b"{}", props(b"unknown")
    )
    assert orchestrator.counters.late == 1
    assert published == []
