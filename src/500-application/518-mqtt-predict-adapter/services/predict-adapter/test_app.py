"""Unit tests for backend calls and request handling."""

import base64
import json

import httpx
import pytest
from app import Adapter, BackendError, PredictBackend, request_context
from models import AdapterConfig, PredictItem
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties

TOPIC = "predict/v1/client-a/model/sensor-anomaly/request"
REPLY = "predict/v1/client-a/model/sensor-anomaly/response"
TRACEPARENT = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"


def predict_response(outputs) -> httpx.Response:
    data = base64.b64encode(json.dumps(outputs).encode()).decode()
    item = {"content_type": "application/json", "encoder": "base64", "data": data}
    return httpx.Response(200, json={"items": [item]})


def make_backend(handler, tmp_path, **overrides) -> PredictBackend:
    token = tmp_path / "token"
    token.write_text("sat-token\n", encoding="utf-8")
    cfg = AdapterConfig(
        allowed_models=("sensor-anomaly",),
        backend_auth_file=str(token),
        **overrides,
    )
    client = httpx.Client(transport=httpx.MockTransport(handler))
    return PredictBackend(cfg, client=client, sleep=lambda _: None)


class TestBackend:
    def test_sends_items_and_bearer_token(self, tmp_path):
        seen = {}

        def handler(request: httpx.Request) -> httpx.Response:
            seen["url"] = str(request.url)
            seen["auth"] = request.headers["Authorization"]
            seen["body"] = json.loads(request.content)
            return predict_response([[0.1, 0.9]])

        backend = make_backend(handler, tmp_path)
        assert backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1,2]]")) == [[0.1, 0.9]]
        assert seen["url"].startswith("https://sensor-anomaly.foundry-local-operator")
        assert seen["auth"] == "Bearer sat-token"
        item = seen["body"]["items"][0]
        assert base64.b64decode(item["data"]) == b"[[1,2]]"

    def test_rereads_token_for_every_call(self, tmp_path):
        tokens = []

        def handler(request):
            tokens.append(request.headers["Authorization"])
            return predict_response([1])

        backend = make_backend(handler, tmp_path)
        backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
        (tmp_path / "token").write_text("rotated", encoding="utf-8")
        backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
        assert tokens == ["Bearer sat-token", "Bearer rotated"]

    def test_retries_transient_failures(self, tmp_path):
        calls = []

        def handler(request):
            calls.append(1)
            return httpx.Response(503) if len(calls) == 1 else predict_response([1])

        backend = make_backend(handler, tmp_path)
        assert backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]")) == [1]
        assert len(calls) == 2

    @pytest.mark.parametrize(
        ("status", "code", "attempts"),
        [
            (401, "BACKEND_UNAUTHORIZED", 1),
            (404, "MODEL_UNAVAILABLE", 1),
            (400, "BACKEND_REJECTED", 1),
            (500, "BACKEND_ERROR", 2),
            (503, "BACKEND_UNAVAILABLE", 2),
        ],
    )
    def test_maps_http_errors(self, tmp_path, status, code, attempts):
        calls = []

        def handler(request):
            calls.append(1)
            return httpx.Response(status, text="echoed input [1,2,3]")

        with pytest.raises(BackendError) as raised:
            make_backend(handler, tmp_path).predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
        assert raised.value.code == code
        assert len(calls) == attempts

    def test_rejects_oversize_responses(self, tmp_path):
        def declared(request):
            return predict_response(list(range(100)))

        def streamed(request):
            return httpx.Response(200, content=iter([b'{"items": [', b" " * 200, b"]}"]))

        for handler in (declared, streamed):
            with pytest.raises(BackendError) as raised:
                backend = make_backend(handler, tmp_path, max_response_bytes=64)
                backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
            assert (raised.value.code, raised.value.retryable) == ("OUTPUT_TOO_LARGE", False)

    @pytest.mark.parametrize(
        "content",
        [b'{"items": [1]}', b'{"items": ["x"]}', b"[" * 100_000 + b"]" * 100_000, b'{"items": NaN}'],
        ids=["number-item", "string-item", "nested", "nan"],
    )
    def test_rejects_invalid_response_bodies(self, tmp_path, content):
        with pytest.raises(BackendError) as raised:
            make_backend(lambda request: httpx.Response(200, content=content), tmp_path).predict(
                "sensor-anomaly", PredictItem("application/json", b"[[1]]")
            )
        assert raised.value.code == "BACKEND_INVALID_RESPONSE"

    def test_sets_explicit_phase_timeouts(self, tmp_path):
        seen = {}

        def handler(request):
            seen.update(request.extensions["timeout"])
            return predict_response([1])

        make_backend(handler, tmp_path, backend_timeout_seconds=12).predict(
            "sensor-anomaly", PredictItem("application/json", b"[[1]]")
        )
        assert seen == {"connect": 5.0, "read": 12, "write": 5.0, "pool": 5.0}

    def test_caps_attempts_at_the_request_deadline(self, tmp_path):
        now = [100.0]
        reads = []

        def handler(request):
            reads.append(request.extensions["timeout"]["read"])
            return httpx.Response(503)

        backend = make_backend(handler, tmp_path)
        backend._clock = lambda: now[0]
        with pytest.raises(BackendError) as raised:
            backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"), deadline=100.3)
        assert raised.value.code == "BACKEND_UNAVAILABLE"
        assert reads == [pytest.approx(0.3)]
        with pytest.raises(BackendError) as raised:
            backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"), deadline=99.0)
        assert raised.value.code == "REQUEST_EXPIRED"
        assert len(reads) == 1

    def test_enforces_the_attempt_deadline_while_reading(self, tmp_path):
        now = [0.0]

        def chunks():
            yield b'{"items": '
            now[0] += 31
            yield b"[]}"

        backend = make_backend(lambda request: httpx.Response(200, content=chunks()), tmp_path, backend_attempts=1)
        backend._clock = lambda: now[0]
        with pytest.raises(BackendError) as raised:
            backend.predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
        assert raised.value.code == "BACKEND_TIMEOUT"

    def test_maps_connection_errors(self, tmp_path):
        def handler(request):
            raise httpx.ConnectError("refused")

        with pytest.raises(BackendError) as raised:
            make_backend(handler, tmp_path).predict("sensor-anomaly", PredictItem("application/json", b"[[1]]"))
        assert raised.value.code == "BACKEND_UNAVAILABLE"
        assert raised.value.retryable


class FakeClient:
    def __init__(self):
        self.published = []

    def publish(self, topic, payload, qos, properties):
        self.published.append((topic, json.loads(payload), properties))

        class Info:
            rc = 0

        return Info()


class FakeBackend:
    def __init__(self, result=None, error=None):
        self.result = result
        self.error = error
        self.calls = []

    def predict(self, model_id, item, deadline=None):
        self.calls.append((model_id, item))
        if self.error:
            raise self.error
        return self.result


def make_adapter(backend, clock=None, **overrides) -> Adapter:
    config = AdapterConfig(allowed_models=("sensor-anomaly",), use_tls=False, sat_file=None, **overrides)
    adapter = Adapter(config, backend, clock) if clock else Adapter(config, backend)
    adapter.client = FakeClient()
    return adapter


def request_properties(correlation: bytes | None = None, expiry: int | None = None, **user) -> Properties:
    properties = Properties(PacketTypes.PUBLISH)
    if user:
        properties.UserProperty = list(user.items())
    if correlation is not None:
        properties.CorrelationData = correlation
    if expiry is not None:
        properties.MessageExpiryInterval = expiry
    return properties


class Message:
    def __init__(self, topic: str, payload: bytes, retain: bool = False, properties=None):
        self.topic = topic
        self.payload = payload
        self.retain = retain
        self.properties = properties


def run(adapter: Adapter, topic: str, payload: bytes, properties=None):
    adapter.handle(topic, payload, properties)
    adapter.executor.shutdown(wait=True)
    adapter.drain()
    return adapter.client.published


class TestAdapter:
    def test_publishes_success_with_request_context(self):
        adapter = make_adapter(FakeBackend(result=[[0.2, 0.8]]))
        published = run(
            adapter,
            TOPIC,
            b'{"inputs": [1, 2]}',
            request_properties(b"corr-1", id="req-1", traceparent=TRACEPARENT),
        )
        topic, body, properties = published[0]
        assert topic == REPLY
        assert body["status"] == "success"
        assert body["outputs"] == [[0.2, 0.8]]
        assert body["request_id"] == "req-1"
        assert body["model_id"] == "sensor-anomaly"
        attributes = dict(properties.UserProperty)
        assert len(properties.UserProperty) == len(attributes) == 8
        assert attributes["type"] == "edge-ai.predict.response"
        assert attributes["subject"] == "sensor-anomaly"
        assert attributes["traceparent"] == TRACEPARENT
        assert properties.CorrelationData == b"corr-1"
        assert adapter.counters.succeeded == 1
        assert adapter.in_flight == 0

    def test_rejects_unknown_model_without_calling_backend(self):
        backend = FakeBackend(result=[1])
        published = run(make_adapter(backend), "predict/v1/client-a/model/other/request", b'{"inputs": [1]}')
        assert published[0][0] == "predict/v1/client-a/model/other/response"
        assert published[0][1]["error"]["code"] == "UNKNOWN_MODEL"
        assert backend.calls == []

    def test_rejects_invalid_payload(self):
        published = run(make_adapter(FakeBackend(result=[1])), TOPIC, b"{}")
        assert published[0][1]["error"]["code"] == "INVALID_PAYLOAD"

    def test_echoes_context_on_success_and_error(self):
        payload = b'{"inputs": [1], "context": {"asset_id": "asset-01"}}'
        body = run(make_adapter(FakeBackend(result=[1])), TOPIC, payload)[0][1]
        assert body["context"] == {"asset_id": "asset-01"}
        error = BackendError("BACKEND_TIMEOUT", retryable=True)
        body = run(make_adapter(FakeBackend(error=error)), TOPIC, payload)[0][1]
        assert (body["status"], body["context"]) == ("error", {"asset_id": "asset-01"})

    def test_reports_backend_error_without_upstream_detail(self):
        adapter = make_adapter(FakeBackend(error=BackendError("MODEL_UNAVAILABLE", retryable=False, status=404)))
        body = run(adapter, TOPIC, b'{"inputs": [1]}')[0][1]
        assert body["error"] == {
            "code": "MODEL_UNAVAILABLE",
            "message": "model endpoint call failed",
            "retryable": False,
        }
        assert "outputs" not in body
        assert adapter.counters.by_error == {"MODEL_UNAVAILABLE": 1}

    def test_answers_busy_at_concurrency_limit(self):
        adapter = make_adapter(FakeBackend(result=[1]), max_concurrency=1)
        adapter.in_flight = 1
        body = run(adapter, TOPIC, b'{"inputs": [1]}')[0][1]
        assert body["error"]["code"] == "BUSY"
        assert body["error"]["retryable"] is True

    def test_ignores_non_request_topics(self):
        assert run(make_adapter(FakeBackend(result=[1])), REPLY, b'{"inputs": [1]}') == []

    def test_deeply_nested_request_is_answered_without_crashing(self):
        adapter = make_adapter(FakeBackend(result=[1]))
        adapter._on_message(None, None, Message(TOPIC, b"[" * 200_000 + b"]" * 200_000))
        adapter._on_message(None, None, Message(TOPIC, b'{"inputs": [1], "context": ' + b'{"a":' * 50_000 + b"}"))
        adapter.drain()
        assert [item[1]["error"]["code"] for item in adapter.client.published] == ["INVALID_JSON", "INVALID_JSON"]
        assert adapter.counters.unhandled == 0

    def test_contains_unexpected_handler_errors(self, monkeypatch):
        adapter = make_adapter(FakeBackend(result=[1]))
        monkeypatch.setattr(adapter, "handle", lambda *args: (_ for _ in ()).throw(RecursionError()))
        adapter._on_message(None, None, Message(TOPIC, b"{}"))
        assert adapter.counters.unhandled == 1

    def test_ignores_retained_requests(self):
        adapter = make_adapter(FakeBackend(result=[1]))
        adapter._on_message(None, None, Message(TOPIC, b'{"inputs": [1]}', retain=True))
        adapter.drain()
        assert adapter.client.published == []
        assert (adapter.counters.retained, adapter.counters.received) == (1, 0)

    def test_drops_expired_requests_without_answering(self):
        backend = FakeBackend(result=[1])
        adapter = make_adapter(backend)
        assert run(adapter, TOPIC, b'{"inputs": [1]}', request_properties(expiry=0)) == []
        assert backend.calls == []
        assert adapter.counters.expired == 1

    def test_passes_the_expiry_deadline_and_drops_late_results(self):
        now = [50.0]

        class SlowBackend(FakeBackend):
            def predict(self, model_id, item, deadline=None):
                self.deadline = deadline
                now[0] = deadline
                return [1]

        backend = SlowBackend()
        adapter = make_adapter(backend, clock=lambda: now[0])
        assert run(adapter, TOPIC, b'{"inputs": [1]}', request_properties(expiry=5)) == []
        assert backend.deadline == 55.0
        assert (adapter.counters.expired, adapter.counters.succeeded, adapter.in_flight) == (1, 0, 0)

    def test_answers_busy_while_shutting_down(self):
        adapter = make_adapter(FakeBackend(result=[1]))
        adapter.stopping = True
        body = run(adapter, TOPIC, b'{"inputs": [1]}')[0][1]
        assert (body["error"]["code"], body["error"]["retryable"]) == ("BUSY", True)


def test_request_context_drops_oversize_correlation_and_invalid_traceparent():
    _, correlation, traceparent = request_context(request_properties(b"x" * 257, traceparent="bogus"))
    assert correlation is None
    assert traceparent is None
