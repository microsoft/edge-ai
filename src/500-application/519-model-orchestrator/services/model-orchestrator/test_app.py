"""Unit tests for the orchestration state machine."""

import json
import random

from app import Orchestrator, Runtime
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


def make(models=MODELS, **env):
    published = []
    clock = Clock()

    def publish(topic, payload, properties):
        published.append((topic, payload, properties))
        return True

    config = OrchestratorConfig.from_env({"MODELS": models, "AIO_SAT_FILE": "", **env})
    orchestrator = Orchestrator(config, publish, clock, random.Random(1))  # noqa: S311
    return orchestrator, published, clock


def props(correlation: bytes | None = None, **user) -> Properties:
    properties = Properties(PacketTypes.PUBLISH)
    if user:
        properties.UserProperty = list(user.items())
    if correlation is not None:
        properties.CorrelationData = correlation
    return properties


def requests_for(published, model_id):
    return [item for item in published if item[0] == f"predict/v1/model-orchestrator/model/{model_id}/request"]


def answer(orchestrator, published, model_id, score=None, error=None, index=-1):
    topic, _, properties = requests_for(published, model_id)[index]
    if error:
        body = json.dumps({"status": "error", "error": error}).encode()
    else:
        body = json.dumps({"status": "success", "latency_ms": 3, "outputs": {"score": score}}).encode()
    orchestrator.handle_predict_response(
        topic.replace("/request", "/response"), body, props(properties.CorrelationData)
    )


def many_models(count: int) -> str:
    return json.dumps(
        [{"id": f"m{i}", "result": {"kind": "score", "field": "score", "threshold": 0.5}} for i in range(count)]
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
    orchestrator.tick()
    body, _ = final(published)
    assert (body["status"], body["decision"]) == ("partial", "unknown")
    answer(orchestrator, published, "model-b", 0.9)
    assert orchestrator.counters.late == 1
    assert len([item for item in published if item[0] == RESPONSE]) == 1


def test_answer_after_deadline_before_tick_is_late_not_success():
    orchestrator, published, clock = make(TIMEOUT_SECONDS="5")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    answer(orchestrator, published, "model-a", 0.1)
    clock.now += 5
    answer(orchestrator, published, "model-b", 0.9)
    body, _ = final(published)
    assert (body["status"], body["decision"]) == ("partial", "unknown")
    assert orchestrator.counters.late == 1
    assert orchestrator.counters.complete == 0
    assert orchestrator.in_flight == 0
    orchestrator.tick()
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


def test_rejects_invalid_and_busy_requests():
    orchestrator, published, _ = make(MAX_PENDING="1")
    orchestrator.handle_request(REQUEST, b"{}", props())
    assert final(published)[0]["error"]["code"] == "INVALID_PAYLOAD"

    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-1"))
    orchestrator.handle_request(REQUEST, b'{"inputs": [1], "context": {"asset_id": "a-2"}}', props(id="req-2"))
    body = final(published)[0]
    assert body["error"] == {"code": "BUSY", "retryable": True}
    assert (body["request_id"], body["context"]) == ("req-2", {"asset_id": "a-2"})


def test_silently_drops_repeats_of_a_pending_request():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(b"corr", id="req-1"))
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(b"corr", id="req-1"))
    assert len(published) == 2
    assert (orchestrator.counters.duplicate_request, orchestrator.counters.rejected) == (1, 0)
    answer(orchestrator, published, "model-a", 0.1)
    answer(orchestrator, published, "model-b", 0.1)
    assert len([item for item in published if item[0] == RESPONSE]) == 1


def test_echoes_context_on_success_and_rejection():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1], "context": {"asset_id": "a-1"}}', props())
    answer(orchestrator, published, "model-a", 0.1)
    answer(orchestrator, published, "model-b", 0.1)
    assert final(published)[0]["context"] == {"asset_id": "a-1"}
    orchestrator.handle_request(REQUEST, b'{"inputs": ["x"], "context": {"asset_id": "a-1"}}', props())
    body = final(published)[0]
    assert (body["status"], body["context"]) == ("rejected", {"asset_id": "a-1"})
    orchestrator.handle_request(REQUEST, b'{"inputs": [1], "context": "a-1"}', props())
    body = final(published)[0]
    assert body["error"]["code"] == "INVALID_PAYLOAD"
    assert "context" not in body


def test_sets_message_expiry_to_the_remaining_deadline():
    orchestrator, published, clock = make(TIMEOUT_SECONDS="2.5", MAX_INFLIGHT_MODEL_CALLS="1")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    assert published[0][2].MessageExpiryInterval == 3
    clock.now += 2.2
    answer(orchestrator, published, "model-a", 0.1)
    assert requests_for(published, "model-b")[0][2].MessageExpiryInterval == 1


def test_limits_in_flight_model_calls_and_queues_the_rest():
    orchestrator, published, _ = make(MAX_INFLIGHT_MODEL_CALLS="4")
    for index in range(6):
        orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id=f"req-{index}"))
    assert len(published) == 4
    assert orchestrator.in_flight == 4
    while orchestrator.pending:
        topic, _, properties = next(
            item
            for item in published
            if item[0].endswith("/request")
            and (fanout := orchestrator.pending.get(item[2].CorrelationData.decode()))
            and topic_model(item[0]) in fanout.in_flight
        )
        answer_topic(orchestrator, topic, properties, 0.1)
        assert orchestrator.in_flight <= 4
    responses = [json.loads(item[1]) for item in published if item[0] == RESPONSE]
    assert [body["status"] for body in responses] == ["complete"] * 6
    assert orchestrator.in_flight == 0


def topic_model(topic):
    return topic.split("/")[4]


def answer_topic(orchestrator, topic, properties, score):
    body = json.dumps({"status": "success", "outputs": {"score": score}}).encode()
    orchestrator.handle_predict_response(
        topic.replace("/request", "/response"), body, props(properties.CorrelationData)
    )


def test_queued_calls_time_out_without_being_sent():
    orchestrator, published, clock = make(models=many_models(3), MAX_INFLIGHT_MODEL_CALLS="1", TIMEOUT_SECONDS="5")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    clock.now += 5
    orchestrator.tick()
    body = final(published)[0]
    assert len(published) == 2
    assert body["counts"]["timed_out"] == 3
    assert body["retryable"] is True
    assert orchestrator.in_flight == 0


def test_retries_busy_with_jitter_while_time_remains():
    orchestrator, published, clock = make(TIMEOUT_SECONDS="5")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    busy = {"code": "BUSY", "retryable": True}
    answer(orchestrator, published, "model-a", error=busy)
    assert orchestrator.counters.busy_retries == 1
    assert len(requests_for(published, "model-a")) == 1
    orchestrator.tick()
    assert len(requests_for(published, "model-a")) == 1
    clock.now += 0.1
    orchestrator.tick()
    retry = requests_for(published, "model-a")
    assert len(retry) == 2
    assert retry[1][2].CorrelationData == retry[0][2].CorrelationData
    answer(orchestrator, published, "model-a", 0.9)
    answer(orchestrator, published, "model-b", 0.1)
    body = final(published)[0]
    assert (body["status"], body["decision"], body["retryable"]) == ("complete", "anomaly", False)


def test_reports_busy_when_no_time_remains_for_a_retry():
    orchestrator, published, clock = make(TIMEOUT_SECONDS="1")
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    clock.now += 0.99
    answer(orchestrator, published, "model-a", error={"code": "BUSY", "retryable": True})
    answer(orchestrator, published, "model-b", 0.1)
    body = final(published)[0]
    assert body["models"][0] == {"model_id": "model-a", "status": "failed", "error_code": "BUSY"}
    assert (body["status"], body["retryable"]) == ("partial", True)


def test_shutdown_publishes_pending_requests():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(id="req-1"))
    answer(orchestrator, published, "model-a", 0.1)
    orchestrator.shutdown()
    body = final(published)[0]
    assert body["models"][1] == {"model_id": "model-b", "status": "timed_out", "error_code": "SHUTDOWN"}
    assert orchestrator.pending == {}
    assert orchestrator.in_flight == 0


def test_ignores_retained_messages():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props(), retain=True)
    orchestrator.handle_predict_response(
        "predict/v1/model-orchestrator/model/model-a/response", b"{}", props(b"x"), retain=True
    )
    assert published == []
    assert (orchestrator.counters.retained, orchestrator.counters.received) == (2, 0)


class Message:
    def __init__(self, topic, payload):
        self.topic = topic
        self.payload = payload
        self.retain = False
        self.properties = props(b"x")


def test_deeply_nested_messages_do_not_stop_the_runtime(monkeypatch):
    runtime = Runtime(OrchestratorConfig.from_env({"MODELS": MODELS, "AIO_MQTT_USE_TLS": "false", "AIO_SAT_FILE": ""}))
    published = []
    monkeypatch.setattr(runtime.orchestrator, "publish", lambda *args: published.append(args) or True)
    nested = b"[" * 200_000 + b"]" * 200_000
    runtime._on_request(None, None, Message(REQUEST, nested))
    assert json.loads(published[-1][1])["error"]["code"] == "INVALID_JSON"
    runtime._on_request(None, None, Message(REQUEST, b'{"inputs": [1]}'))
    key = published[-1][2].CorrelationData
    message = Message("predict/v1/model-orchestrator/model/model-a/response", nested)
    message.properties = props(key)
    runtime._on_predict_response(None, None, message)
    fanout = next(iter(runtime.orchestrator.pending.values()))
    assert fanout.outcomes["model-a"].error_code == "INVALID_RESPONSE"
    monkeypatch.setattr(runtime.orchestrator, "handle_request", lambda *args: (_ for _ in ()).throw(RecursionError()))
    runtime._on_request(None, None, Message(REQUEST, b"{}"))
    assert runtime.orchestrator.counters.unhandled == 1


def test_ignores_responses_for_other_clients_and_unknown_correlation():
    orchestrator, published, _ = make()
    orchestrator.handle_predict_response("predict/v1/someone-else/model/model-a/response", b"{}", props(b"x"))
    orchestrator.handle_predict_response(
        "predict/v1/model-orchestrator/model/model-a/response", b"{}", props(b"unknown")
    )
    assert orchestrator.counters.late == 1
    assert published == []


def test_ignores_answers_for_models_not_in_flight():
    orchestrator, published, _ = make()
    orchestrator.handle_request(REQUEST, b'{"inputs": [1]}', props())
    topic, _, properties = requests_for(published, "model-a")[0]
    orchestrator.handle_predict_response(
        "predict/v1/model-orchestrator/model/unknown/response", b"{}", props(properties.CorrelationData)
    )
    assert orchestrator.counters.duplicate == 1
