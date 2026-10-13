"""Unit tests for review fixes: MQTT trigger auth, identity, timestamps, stitching, and SAS reuse."""

import json
import sys
import threading
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
    def __init__(self, mid: int):
        self.mid = mid
        self.rc = 0


class FakeMqttClient:
    """Records how the trigger connects and publishes, without a network.

    `puback_reason` is the PUBACK reason code, or None for no acknowledgment.
    `ack_timing` delivers the PUBACK before publish() returns ("early") or
    from another thread afterwards ("late").
    """

    instances: list["FakeMqttClient"] = []
    connect_reason = 0
    puback_reason: int | None = 0
    ack_timing = "early"

    def __init__(self, callback_api_version, client_id, protocol):
        self.client_id = client_id
        self.protocol = protocol
        self.on_connect = None
        self.on_publish = None
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
        info = FakeMessageInfo(mid=len(self.publishes))
        if FakeMqttClient.puback_reason is not None:
            reason = ReasonCode(PacketTypes.PUBACK, identifier=FakeMqttClient.puback_reason)
            if FakeMqttClient.ack_timing == "early":
                self.on_publish(self, None, info.mid, reason, None)
            else:
                threading.Timer(0.05, self.on_publish, (self, None, info.mid, reason, None)).start()
        return info

    def disconnect(self):
        self.disconnected = True


@pytest.fixture
def fake_mqtt(monkeypatch):
    FakeMqttClient.instances = []
    FakeMqttClient.connect_reason = 0
    FakeMqttClient.puback_reason = 0
    FakeMqttClient.ack_timing = "early"
    credential = MagicMock()
    credential.get_token.return_value = FakeToken()
    monkeypatch.setattr(function_app.mqtt, "Client", FakeMqttClient)
    monkeypatch.setattr(function_app, "ManagedIdentityCredential", MagicMock(return_value=credential))
    monkeypatch.setattr(function_app, "_trigger_rate_limits", {})
    monkeypatch.setattr(function_app, "MQTT_TIMEOUT_SECONDS", 0.5)
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
        fake_mqtt.puback_reason = None

        with pytest.raises(TimeoutError):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

    @pytest.mark.parametrize("timing", ["early", "late"])
    def test_successful_puback_is_accepted_whenever_it_arrives(self, fake_mqtt, timing):
        fake_mqtt.ack_timing = timing

        function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

        assert fake_mqtt.instances[0].disconnected

    @pytest.mark.parametrize("timing", ["early", "late"])
    def test_negative_puback_raises(self, fake_mqtt, timing):
        fake_mqtt.puback_reason = 0x87  # Not authorized
        fake_mqtt.ack_timing = timing

        with pytest.raises(PermissionError, match="Not authorized"):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

    def test_negative_puback_returns_502_without_starting_the_cooldown(self, fake_mqtt):
        fake_mqtt.puback_reason = 0x87

        response = function_app.trigger_capture(_request("trigger", "POST", {"camera": "camera-01"}))

        assert response.status_code == 502
        assert _json(response) == {"error": "Trigger delivery failed"}
        assert function_app._trigger_rate_limits == {}

        fake_mqtt.puback_reason = 0
        assert function_app.trigger_capture(_request("trigger", "POST", {"camera": "camera-01"})).status_code == 202

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

        assert fake_mqtt.instances[0].client_id.startswith("trigger-a-")

    def test_each_publish_uses_a_unique_client_id(self, fake_mqtt):
        for _ in range(3):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

        client_ids = [client.client_id for client in fake_mqtt.instances]
        assert len(set(client_ids)) == 3
        assert all(client_id.startswith("video-query-trigger-") for client_id in client_ids)


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


class TestSegmentMetadata:
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
        assert not hasattr(function_app, "query_blobs_by_tags")
