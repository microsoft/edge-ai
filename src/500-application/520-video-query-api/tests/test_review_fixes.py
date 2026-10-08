"""Unit tests for review fixes: MQTT trigger auth, identity, timestamps, stitching, and SAS reuse."""

import json
import sys
from datetime import datetime
from pathlib import Path
from unittest.mock import MagicMock

import azure.functions as func
import pytest
from paho.mqtt.reasoncodes import ReasonCode

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import function_app  # noqa: E402
from paho.mqtt.packettypes import PacketTypes  # noqa: E402


def _request(route: str, method: str = "GET", params: dict | None = None) -> func.HttpRequest:
    return func.HttpRequest(method=method, url=f"/api/{route}", params=params or {}, body=b"")


def _json(response: func.HttpResponse) -> dict:
    return json.loads(response.get_body())


class FakeToken:
    token = "header.payload.signature"  # noqa: S105 - synthetic test token


class FakeMessageInfo:
    def __init__(self, published: bool):
        self._published = published

    def wait_for_publish(self, timeout=None):
        return None

    def is_published(self):
        return self._published


class FakeMqttClient:
    """Records how the trigger connects and publishes, without a network."""

    instances: list["FakeMqttClient"] = []
    connect_reason = 0
    published = True

    def __init__(self, callback_api_version, client_id, protocol):
        self.client_id = client_id
        self.protocol = protocol
        self.on_connect = None
        self.connect_properties = None
        self.username = None
        self.publishes: list[tuple] = []
        self.disconnected = False
        FakeMqttClient.instances.append(self)

    def tls_set(self, tls_version):
        self.tls_version = tls_version

    def username_pw_set(self, username, password=None):
        self.username = username

    def connect(self, host, port, properties=None):
        self.host, self.port, self.connect_properties = host, port, properties

    def loop_start(self):
        reason = ReasonCode(PacketTypes.CONNACK, identifier=FakeMqttClient.connect_reason)
        self.on_connect(self, None, None, reason, None)

    def loop_stop(self):
        pass

    def publish(self, topic, payload, qos):
        self.publishes.append((topic, payload, qos))
        return FakeMessageInfo(FakeMqttClient.published)

    def disconnect(self):
        self.disconnected = True


@pytest.fixture
def fake_mqtt(monkeypatch):
    FakeMqttClient.instances = []
    FakeMqttClient.connect_reason = 0
    FakeMqttClient.published = True
    credential = MagicMock()
    credential.get_token.return_value = FakeToken()
    monkeypatch.setattr(function_app.mqtt, "Client", FakeMqttClient)
    monkeypatch.setattr(function_app, "ManagedIdentityCredential", MagicMock(return_value=credential))
    monkeypatch.setattr(function_app, "_trigger_rate_limits", {})
    monkeypatch.setenv("TRIGGER_ALLOWED_CAMERAS", "camera-01")
    monkeypatch.setenv("EVENT_GRID_HOSTNAME", "ns.region-1.ts.eventgrid.azure.net")
    return FakeMqttClient


class TestMqttTrigger:
    def test_authenticates_with_oauth2_jwt_enhanced_auth(self, fake_mqtt):
        function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

        client = fake_mqtt.instances[0]
        assert client.connect_properties.AuthenticationMethod == "OAUTH2-JWT"
        assert client.connect_properties.AuthenticationData == b"header.payload.signature"
        assert client.username is None
        assert client.port == 8883
        assert client.disconnected

    def test_refused_connection_raises(self, fake_mqtt):
        fake_mqtt.connect_reason = 135  # Not authorized

        with pytest.raises(ConnectionError):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")
        assert fake_mqtt.instances[0].publishes == []

    def test_unacknowledged_publish_raises(self, fake_mqtt):
        fake_mqtt.published = False

        with pytest.raises(TimeoutError):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

    def test_trigger_publishes_to_camera_topic_with_camera_in_payload(self, fake_mqtt):
        response = function_app.trigger_capture(_request("trigger", "POST", {"camera": "camera-01"}))

        assert response.status_code == 202
        topic, payload, qos = fake_mqtt.instances[0].publishes[0]
        assert topic == "alerts/trigger/camera-01"
        assert qos == 1
        device_data = json.loads(payload)["attributes"]["devices"][0]["device_data"]
        assert device_data["camera_id"] == "camera-01"
        assert device_data["type"] == "ALERT_DLQC"

    def test_refused_connection_returns_502(self, fake_mqtt):
        fake_mqtt.connect_reason = 135

        response = function_app.trigger_capture(_request("trigger", "POST", {"camera": "camera-01"}))

        assert response.status_code == 502
        assert _json(response) == {"error": "Trigger delivery failed"}

    def test_mqtt_client_id_is_separate_from_identity(self, fake_mqtt, monkeypatch):
        monkeypatch.setenv("MQTT_CLIENT_ID", "trigger-a")
        monkeypatch.setenv("AZURE_CLIENT_ID", "00000000-0000-0000-0000-000000000001")

        function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

        assert fake_mqtt.instances[0].client_id == "trigger-a"


class TestManagedIdentity:
    def test_uses_system_assigned_identity_without_client_id(self, monkeypatch):
        monkeypatch.delenv("AZURE_CLIENT_ID", raising=False)
        factory = MagicMock()
        monkeypatch.setattr(function_app, "ManagedIdentityCredential", factory)

        function_app._managed_identity_credential()

        factory.assert_called_once_with(client_id=None)

    def test_uses_user_assigned_identity_with_client_id(self, monkeypatch):
        monkeypatch.setenv("AZURE_CLIENT_ID", "00000000-0000-0000-0000-000000000001")
        factory = MagicMock()
        monkeypatch.setattr(function_app, "ManagedIdentityCredential", factory)

        function_app._managed_identity_credential()

        factory.assert_called_once_with(client_id="00000000-0000-0000-0000-000000000001")


class TestQueryTime:
    @pytest.mark.parametrize(
        ("value", "expected"),
        [
            ("2026-10-07T10:00:00+02:00", datetime(2026, 10, 7, 8, 0)),
            ("2026-10-07T10:00:00-05:30", datetime(2026, 10, 7, 15, 30)),
            ("2026-10-07T10:00:00Z", datetime(2026, 10, 7, 10, 0)),
            ("2026-10-07T10:00:00", datetime(2026, 10, 7, 10, 0)),
        ],
    )
    def test_converts_offsets_to_naive_utc(self, value, expected):
        parsed = function_app.parse_query_time(value)

        assert parsed == expected
        assert parsed.tzinfo is None


class TestStitchLimit:
    def test_rejects_stitch_window_over_limit_before_storage_access(self, monkeypatch):
        monkeypatch.setenv("STITCH_MAX_DURATION_SECONDS", "1800")
        monkeypatch.setenv("STORAGE_ACCOUNT_NAME", "account")
        storage = MagicMock()
        monkeypatch.setattr(function_app, "BlobServiceClient", storage)

        response = function_app.get_video(
            _request(
                "video",
                params={
                    "camera": "camera-01",
                    "start": "2026-01-01T00:00:00Z",
                    "end": "2026-01-01T01:00:00Z",
                    "stitch": "true",
                },
            )
        )

        assert response.status_code == 400
        assert _json(response) == {"error": "Stitched query window too long", "max_stitch_duration_seconds": 1800}
        storage.assert_not_called()

    @pytest.mark.parametrize("value", ["", "abc", "0", "-5"])
    def test_invalid_limit_falls_back_to_default(self, monkeypatch, value):
        monkeypatch.setenv("STITCH_MAX_DURATION_SECONDS", value)

        assert function_app.stitch_max_seconds() == function_app.DEFAULT_STITCH_MAX_SECONDS


class TestSegmentResponse:
    def test_requests_one_user_delegation_key_per_query(self, monkeypatch):
        monkeypatch.setenv("STORAGE_ACCOUNT_NAME", "account")
        monkeypatch.delenv("STORAGE_CONNECTION_STRING", raising=False)
        service = MagicMock()
        service.account_name = "account"
        service.get_blob_client.return_value.url = "https://account.blob.core.windows.net/c/b"
        service.get_user_delegation_key.return_value = MagicMock()
        monkeypatch.setattr(function_app, "BlobServiceClient", MagicMock(return_value=service))
        monkeypatch.setattr(function_app, "ManagedIdentityCredential", MagicMock())
        monkeypatch.setattr(function_app, "generate_blob_sas", MagicMock(return_value="sig=x"))
        segments = [
            {"name": f"camera-01/2026/01/01/00/segment_2026-01-01T00:0{i}:00Z_camera-01.mp4", "timestamp": None}
            for i in range(5)
        ]
        monkeypatch.setattr(function_app, "query_blobs_by_prefix", MagicMock(return_value=segments))
        monkeypatch.setattr(function_app, "fetch_segment_metadata", MagicMock(return_value={"duration_seconds": 60}))

        response = function_app.get_video(
            _request(
                "video",
                params={"camera": "camera-01", "start": "2026-01-01T00:00:00Z", "end": "2026-01-01T00:30:00Z"},
            )
        )

        assert response.status_code == 200
        body = _json(response)
        assert body["total_segments"] == 5
        assert [s["duration_seconds"] for s in body["segments"]] == [60] * 5
        assert service.get_user_delegation_key.call_count == 1

    def test_metadata_fetch_preserves_segment_order(self, monkeypatch):
        names = [f"segment_{i}.mp4" for i in range(20)]
        monkeypatch.setattr(function_app, "fetch_segment_metadata", lambda _container, name: {"name": name})

        results = function_app.fetch_metadata_for_segments(MagicMock(), [{"name": n} for n in names])

        assert [r["name"] for r in results] == names


class TestSegmentDownload:
    def test_streams_segments_to_disk(self, tmp_path):
        container = MagicMock()
        downloader = container.get_blob_client.return_value.download_blob.return_value
        downloader.readinto.side_effect = lambda stream: stream.write(b"frames")

        files = function_app.download_segments(container, [{"name": "a.mp4"}, {"name": "b.mp4"}], tmp_path)

        assert [f.read_bytes() for f in files] == [b"frames", b"frames"]
        downloader.readall.assert_not_called()


class TestRemovedHelpers:
    def test_unused_helpers_are_removed(self):
        assert not hasattr(function_app, "calculate_hash_prefix")
        assert not hasattr(function_app, "TRIGGERED_PATTERNS")
