"""Unit tests for adapter configuration and request contract."""

import base64
import json

import pytest
from models import (
    AdapterConfig,
    PredictItem,
    RequestError,
    build_predict_body,
    decode_predict_response,
    parse_request_payload,
    parse_request_topic,
    request_id,
    tensor_shape,
)
from pydantic import ValidationError

ENV = {"ALLOWED_MODELS": "sensor-anomaly, image-classifier,sensor-anomaly"}


def config(**overrides) -> AdapterConfig:
    return AdapterConfig(allowed_models=("sensor-anomaly",), **overrides)


class TestConfig:
    def test_defaults_from_env(self):
        cfg = AdapterConfig.from_env(ENV)
        assert cfg.allowed_models == ("sensor-anomaly", "image-classifier")
        assert cfg.request_filter == "predict/v1/+/model/+/request"
        assert cfg.response_topic("sensor-simulator", "sensor-anomaly") == (
            "predict/v1/sensor-simulator/model/sensor-anomaly/response"
        )
        assert cfg.endpoint_for("sensor-anomaly") == (
            "https://sensor-anomaly.foundry-local-operator.svc.cluster.local:5000/v1/predict"
        )
        assert cfg.backend_auth_file == "/var/run/secrets/foundry-local/token"

    def test_requires_allowed_models(self):
        with pytest.raises(ValueError, match="ALLOWED_MODELS"):
            AdapterConfig.from_env({})

    @pytest.mark.parametrize("model_id", ["Sensor", "sensor_anomaly", "-sensor", "a" * 64, "a.b"])
    def test_rejects_models_that_are_not_dns_labels(self, model_id):
        with pytest.raises(ValidationError, match="DNS label"):
            AdapterConfig(allowed_models=(model_id,))

    def test_response_kind_must_differ_from_request_kind(self):
        with pytest.raises(ValidationError, match="response_kind"):
            config(response_kind="request")

    @pytest.mark.parametrize(
        "template",
        ["https://models.local/v1/predict", "https://{model_id}/{model_id}", "file:///{model_id}"],
    )
    def test_rejects_invalid_endpoint_templates(self, template):
        with pytest.raises(ValidationError, match="endpoint_template"):
            config(endpoint_template=template)

    def test_empty_token_file_disables_backend_auth(self):
        cfg = AdapterConfig.from_env({**ENV, "BACKEND_AUTH_FILE": ""})
        assert cfg.backend_auth_file is None

    def test_rejects_backend_token_over_plain_http(self):
        with pytest.raises(ValidationError, match="https"):
            config(endpoint_template="http://mock/{model_id}/v1/predict")
        cfg = AdapterConfig.from_env(
            {**ENV, "MODEL_ENDPOINT_TEMPLATE": "http://mock/{model_id}/v1/predict", "BACKEND_AUTH_FILE": ""}
        )
        assert cfg.backend_auth_file is None

    def test_rejects_broker_token_without_tls(self):
        with pytest.raises(ValidationError, match="TLS"):
            AdapterConfig.from_env({**ENV, "AIO_MQTT_USE_TLS": "false"})
        cfg = AdapterConfig.from_env({**ENV, "AIO_MQTT_USE_TLS": "false", "AIO_SAT_FILE": ""})
        assert cfg.sat_file is None

    def test_max_request_seconds_includes_backoff(self):
        assert config().max_request_seconds == 60.5
        assert config(backend_timeout_seconds=4, backend_attempts=3).max_request_seconds == 13.5

    def test_reports_invalid_variable(self):
        with pytest.raises(ValueError, match="MAX_CONCURRENCY"):
            AdapterConfig.from_env({**ENV, "MAX_CONCURRENCY": "many"})


class TestTopics:
    def test_parses_client_and_model(self):
        parsed = parse_request_topic(config(), "predict/v1/client-a/model/sensor-anomaly/request")
        assert (parsed.client, parsed.model_id) == ("client-a", "sensor-anomaly")

    @pytest.mark.parametrize(
        "topic",
        [
            "predict/v1/client-a/model/sensor-anomaly/response",
            "predict/v2/client-a/model/sensor-anomaly/request",
            "predict/v1/client-a/models/sensor-anomaly/request",
            "predict/v1/Client/model/sensor-anomaly/request",
            "predict/v1/client-a/model/sensor-anomaly/request/extra",
        ],
    )
    def test_ignores_other_topics(self, topic):
        assert parse_request_topic(config(), topic) is None


class TestPayload:
    def test_wraps_flat_inputs_in_a_row(self):
        request = parse_request_payload(b'{"inputs": [1, 2.5, 3]}', 1024)
        assert request.item == PredictItem("application/json", b"[[1,2.5,3]]")
        assert request.context is None

    def test_keeps_two_dimensional_inputs(self):
        request = parse_request_payload(b'{"inputs": [[1, 2], [3, 4]]}', 1024)
        assert json.loads(request.item.data) == [[1, 2], [3, 4]]

    def test_accepts_base64_data_with_content_type(self):
        encoded = base64.b64encode(b"\xff\xd8\xff").decode()
        request = parse_request_payload(json.dumps({"data": encoded, "content_type": "image/jpeg"}).encode(), 1024)
        assert request.item == PredictItem("image/jpeg", b"\xff\xd8\xff")

    def test_keeps_context_out_of_the_model_item(self):
        request = parse_request_payload(b'{"inputs": [1], "context": {"asset_id": "asset-01"}}', 1024)
        assert request.context == {"asset_id": "asset-01"}
        assert request.item.data == b"[[1]]"

    @pytest.mark.parametrize("context", ['"asset-01"', "[1]", json.dumps({"k": "x" * 1100})])
    def test_rejects_invalid_context(self, context):
        with pytest.raises(RequestError) as raised:
            parse_request_payload(f'{{"inputs": [1], "context": {context}}}'.encode(), 4096)
        assert raised.value.code == "INVALID_PAYLOAD"

    @pytest.mark.parametrize(
        ("payload", "code"),
        [
            (b"not json", "INVALID_JSON"),
            (b"[1, 2]", "INVALID_PAYLOAD"),
            (b"{}", "INVALID_PAYLOAD"),
            (b'{"inputs": [1], "data": "AA=="}', "INVALID_PAYLOAD"),
            (b'{"inputs": []}', "INVALID_PAYLOAD"),
            (b'{"inputs": ["a"]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [true]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [[[[[[1]]]]]]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [[1, 2], [3]]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [[1], [[2]]]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [1, [2]]}', "INVALID_PAYLOAD"),
            (b'{"inputs": [1e999]}', "INVALID_JSON"),
            (b'{"inputs": [NaN]}', "INVALID_JSON"),
            (b'{"inputs": [-Infinity]}', "INVALID_JSON"),
            (b'{"data": "AA=="}', "INVALID_PAYLOAD"),
            (b'{"data": "not base64!", "content_type": "image/jpeg"}', "INVALID_PAYLOAD"),
        ],
    )
    def test_rejects_invalid_payloads(self, payload, code):
        with pytest.raises(RequestError) as raised:
            parse_request_payload(payload, 1024)
        assert raised.value.code == code

    def test_rejects_deeply_nested_json(self):
        with pytest.raises(RequestError) as raised:
            parse_request_payload(b"[" * 100_000 + b"]" * 100_000, 1024 * 1024)
        assert raised.value.code == "INVALID_JSON"

    def test_rejects_oversize_payload(self):
        with pytest.raises(RequestError) as raised:
            parse_request_payload(b'{"inputs": [1]}', 8)
        assert raised.value.code == "PAYLOAD_TOO_LARGE"


class TestPredictBody:
    def test_round_trips_json_items(self):
        body = build_predict_body(PredictItem("application/json", b"[[1,2]]"))
        assert body["items"][0]["encoder"] == "base64"
        assert decode_predict_response(body) == [[1, 2]]

    def test_returns_binary_outputs_as_base64(self):
        body = build_predict_body(PredictItem("image/png", b"\x89PNG"))
        assert decode_predict_response(body) == {
            "content_type": "image/png",
            "data": base64.b64encode(b"\x89PNG").decode(),
        }

    @pytest.mark.parametrize(
        "body", [{}, {"items": []}, {"items": [{"data": "%%"}]}, [], {"items": [1]}, {"items": ["AA=="]}]
    )
    def test_rejects_undecodable_responses(self, body):
        with pytest.raises(ValueError):
            decode_predict_response(body)


@pytest.mark.parametrize(
    ("value", "shape"),
    [([[1, 2], [3, 4]], (2, 2)), ([[[1.5]]], (1, 1, 1)), ([[1], [2, 3]], None), ([[[[[1]]]]], None), ([[]], None)],
)
def test_tensor_shape(value, shape):
    assert tensor_shape(value) == shape


def test_request_id_is_bounded():
    assert request_id([("id", "req-1")]) == "req-1"
    assert request_id([("id", "x" * 257)]) is None
    assert request_id([]) is None
