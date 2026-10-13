"""Unit tests for discovery, failure propagation, stitching bounds, and MQTT acknowledgments.

Storage is an in-memory fake holding objects in the layout the 503 media
capture service writes: `{camera}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera}.mp4`
with a JSON sidecar, and triggered clips named
`{YYYY-MM-DD}_{HHMMSS}_segment_alert_event_id_{id}.mkv` without one.
"""

import json
import struct
import sys
import threading
from datetime import UTC, datetime, timedelta
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock

import azure.functions as func
import paho.mqtt.client as mqtt
import pytest
from azure.core.exceptions import ClientAuthenticationError, HttpResponseError, ResourceNotFoundError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import function_app  # noqa: E402

CAMERA = "camera-01"
ACCOUNT_KEY = "a2V5"  # base64 of "key"; signs SAS offline


def _request(params: dict) -> func.HttpRequest:
    return func.HttpRequest(method="GET", url="/api/video", params=params, body=b"")


def _json(response: func.HttpResponse) -> dict:
    return json.loads(response.get_body())


def _at(value: str) -> datetime:
    return datetime.fromisoformat(value).astimezone(UTC)


class FakeDownloader:
    def __init__(self, data: bytes, fail_with: Exception | None = None):
        self.size = len(data)
        self._data = data
        self._fail_with = fail_with

    def readall(self) -> bytes:
        if self._fail_with:
            raise self._fail_with
        return self._data

    def readinto(self, stream) -> int:
        stream.write(self._data)
        return self.size


class FakeContainer:
    """In-memory blob container with failure injection."""

    def __init__(self):
        self.blobs: dict[str, bytes] = {}
        self.uploads: list[tuple[str, bool]] = []
        self.list_failure: Exception | None = None
        self.list_failure_after = 0
        self.read_failures: dict[str, Exception] = {}

    def add(self, name: str, data: bytes = b"video") -> None:
        self.blobs[name] = data

    def list_blobs(self, name_starts_with: str):
        """Yield matching blobs; with `list_failure`, raise after `list_failure_after` of them."""
        yielded = 0
        for name in sorted(self.blobs):
            if not name.startswith(name_starts_with):
                continue
            if self.list_failure and yielded == self.list_failure_after:
                raise self.list_failure
            yield SimpleNamespace(name=name, size=len(self.blobs[name]))
            yielded += 1
        if self.list_failure:
            raise self.list_failure

    def get_blob_client(self, name: str):
        container = self

        class _Blob:
            def download_blob(self):
                if name in container.read_failures:
                    raise container.read_failures[name]
                if name not in container.blobs:
                    raise ResourceNotFoundError("The specified blob does not exist.")
                return FakeDownloader(container.blobs[name])

        return _Blob()

    def upload_blob(self, name: str, data, overwrite: bool = False):
        if name in self.blobs and not overwrite:
            raise AssertionError(f"{name} would be overwritten")
        self.blobs[name] = data.read()
        self.uploads.append((name, overwrite))


class FakeService:
    account_name = "account"

    def __init__(self):
        self.containers = {"video-recordings": FakeContainer(), "temp-videos": FakeContainer()}

    def get_container_client(self, name: str) -> FakeContainer:
        return self.containers[name]

    def get_blob_client(self, container: str, blob: str):
        return SimpleNamespace(url=f"https://account.blob.core.windows.net/{container}/{blob}")


def add_segment(container: FakeContainer, start: str, seconds: int, sidecar: dict | None = None) -> str:
    """Add a continuous segment named for `start`, with a 503-style sidecar."""
    begin = _at(start)
    name = f"{CAMERA}/{begin:%Y/%m/%d/%H}/segment_{begin:%Y-%m-%dT%H:%M:%SZ}_{CAMERA}.mp4"
    container.add(name, b"x" * 1000)
    metadata = sidecar or {
        "camera_id": CAMERA,
        "location": "line-1",
        "segment_start": begin.isoformat(),
        "segment_end": (begin + timedelta(seconds=seconds)).isoformat(),
        "duration_seconds": seconds,
        "file_name": name.rsplit("/", 1)[1],
    }
    container.add(name.rsplit(".", 1)[0] + ".json", json.dumps(metadata).encode())
    return name


@pytest.fixture
def storage(monkeypatch):
    service = FakeService()
    monkeypatch.setattr(function_app, "_storage_client", lambda: (service, ACCOUNT_KEY))
    monkeypatch.delenv("VIDEO_BLOB_PREFIX", raising=False)
    monkeypatch.delenv("SEGMENT_LOOKBACK_SECONDS", raising=False)
    return service


def query(start: str, end: str, **extra) -> func.HttpResponse:
    return function_app.get_video(_request({"camera": CAMERA, "start": start, "end": end, **extra}))


class TestOverlapDiscovery:
    def test_returns_a_recording_that_started_before_the_window(self, storage):
        recordings = storage.containers["video-recordings"]
        name = add_segment(recordings, "2026-01-30T10:00:00+00:00", 300)

        response = query("2026-01-30T10:02:00Z", "2026-01-30T10:03:00Z")

        assert response.status_code == 200
        body = _json(response)
        assert [s["name"] for s in body["segments"]] == [name]
        assert body["segments"][0]["timing"] == "metadata"
        assert body["segments"][0]["segment_start"] == "2026-01-30T10:00:00+00:00"

    def test_returns_a_recording_from_the_preceding_hour(self, storage):
        recordings = storage.containers["video-recordings"]
        name = add_segment(recordings, "2026-01-30T09:58:00+00:00", 300)

        response = query("2026-01-30T10:01:00Z", "2026-01-30T10:02:00Z")

        assert [s["name"] for s in _json(response)["segments"]] == [name]

    def test_excludes_recordings_that_end_before_or_start_after_the_window(self, storage):
        recordings = storage.containers["video-recordings"]
        add_segment(recordings, "2026-01-30T09:50:00+00:00", 300)  # ends 09:55
        inside = add_segment(recordings, "2026-01-30T09:58:00+00:00", 300)
        add_segment(recordings, "2026-01-30T10:05:00+00:00", 300)  # starts at the window end

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z")

        assert [s["name"] for s in _json(response)["segments"]] == [inside]

    def test_lookback_is_configurable(self, storage, monkeypatch):
        monkeypatch.setenv("SEGMENT_LOOKBACK_SECONDS", "60")
        add_segment(storage.containers["video-recordings"], "2026-01-30T09:58:00+00:00", 300)

        response = query("2026-01-30T10:01:00Z", "2026-01-30T10:02:00Z")

        assert _json(response)["total_segments"] == 0

    def test_clip_without_a_sidecar_matches_on_its_filename_time(self, storage):
        recordings = storage.containers["video-recordings"]
        clip = f"{CAMERA}/2026/01/30/10/2026-01-30_100130_segment_alert_event_id_7.mkv"
        recordings.add(clip)
        recordings.add(f"{CAMERA}/2026/01/30/10/2026-01-30_100500_segment_alert_event_id_8.mkv")

        response = query("2026-01-30T10:01:00Z", "2026-01-30T10:02:00Z", event_type="alert")

        segments = _json(response)["segments"]
        assert [s["name"] for s in segments] == [clip]
        assert segments[0]["timing"] == "filename"
        assert segments[0]["recording_type"] == "triggered"

    def test_parses_filenames_under_a_shallow_prefix(self):
        assert function_app.parse_timestamp_from_blob_name(
            "camera-01/segment_2026-01-30T10:00:00Z_camera-01.mp4"
        ) == datetime(2026, 1, 30, 10, 0)

    def test_mixed_naive_and_aware_sidecar_timestamps_sort_without_error(self, storage):
        recordings = storage.containers["video-recordings"]
        second = add_segment(
            recordings,
            "2026-01-30T10:01:00+00:00",
            60,
            {"segment_start": "2026-01-30T10:01:00", "segment_end": "2026-01-30T10:02:00", "duration_seconds": 60},
        )
        first = add_segment(recordings, "2026-01-30T10:00:00+00:00", 60)

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z")

        segments = _json(response)["segments"]
        assert [s["name"] for s in segments] == [first, second]
        assert segments[1]["segment_start"] == "2026-01-30T10:01:00+00:00"

    def test_one_user_delegation_key_signs_every_url(self, monkeypatch):
        service = FakeService()
        service.get_user_delegation_key = MagicMock(return_value=MagicMock())
        monkeypatch.setattr(function_app, "_storage_client", lambda: (service, None))
        monkeypatch.setattr(function_app, "generate_blob_sas", MagicMock(return_value="sig=x"))
        for minute in range(5):
            add_segment(service.containers["video-recordings"], f"2026-01-30T10:0{minute}:00+00:00", 60)

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:30:00Z")

        assert _json(response)["total_segments"] == 5
        assert service.get_user_delegation_key.call_count == 1


class TestDiscoveryFailures:
    def test_listing_failure_returns_502_not_an_empty_result(self, storage):
        storage.containers["video-recordings"].list_failure = ClientAuthenticationError(
            "This request is not authorized"
        )

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z")

        assert response.status_code == 502
        assert _json(response) == {"error": "Recording discovery failed"}

    def test_listing_that_fails_partway_returns_502_not_a_partial_result(self, storage):
        recordings = storage.containers["video-recordings"]
        add_segment(recordings, "2026-01-30T10:00:00+00:00", 60)
        add_segment(recordings, "2026-01-30T10:01:00+00:00", 60)
        recordings.list_failure = HttpResponseError("connection reset")
        recordings.list_failure_after = 1

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true")

        assert response.status_code == 502
        assert storage.containers["temp-videos"].uploads == []

    def test_metadata_read_failure_returns_502(self, storage):
        recordings = storage.containers["video-recordings"]
        name = add_segment(recordings, "2026-01-30T10:00:00+00:00", 60)
        recordings.read_failures[name.rsplit(".", 1)[0] + ".json"] = ClientAuthenticationError("denied")

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z")

        assert response.status_code == 502

    def test_missing_oversized_or_malformed_sidecars_are_optional(self, monkeypatch):
        container = FakeContainer()
        container.add("a.json", b"{not json")
        container.add("b.json", b"{}" + b" " * function_app.METADATA_MAX_BYTES)

        assert function_app.fetch_segment_metadata(container, "missing.mp4") is None
        assert function_app.fetch_segment_metadata(container, "a.mp4") is None
        assert function_app.fetch_segment_metadata(container, "b.mp4") is None


class TestStitching:
    @pytest.fixture
    def stitched(self, storage, monkeypatch):
        recordings = storage.containers["video-recordings"]
        add_segment(recordings, "2026-01-30T10:00:00+00:00", 60)
        add_segment(recordings, "2026-01-30T10:01:30+00:00", 60)
        recordings.add(f"{CAMERA}/2026/01/30/10/2026-01-30_100100_segment_alert_event_id_7.mkv")

        def fake_concat(inputs, output, timeout):
            output.write_bytes(b"".join(path.read_bytes() for path in inputs))

        monkeypatch.setattr(function_app, "concat_segments", fake_concat)
        return storage

    def test_results_get_unique_create_only_names(self, stitched):
        first = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")
        second = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert first.status_code == second.status_code == 200
        uploads = stitched.containers["temp-videos"].uploads
        assert len({name for name, _ in uploads}) == 2
        assert all(overwrite is False for _, overwrite in uploads)
        assert _json(first)["video_url"] != _json(second)["video_url"]

    def test_reports_gaps_and_untrimmed_footage_range(self, stitched):
        body = _json(query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous"))

        assert body["trimmed"] is False
        assert body["segment_count"] == 2
        assert body["earliest_segment_start"] == "2026-01-30T10:00:00+00:00"
        assert body["latest_segment_end"] == "2026-01-30T10:02:30+00:00"
        assert body["gap_count"] == 1
        assert body["gaps"][0]["gap_seconds"] == 30

    def test_rejects_mixed_recording_types(self, stitched):
        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true")

        assert response.status_code == 400
        assert _json(response)["recording_types"] == ["continuous", "triggered"]

    def test_rejects_too_many_segments_before_staging(self, stitched, monkeypatch):
        monkeypatch.setenv("STITCH_MAX_SEGMENTS", "1")

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert response.status_code == 400
        assert _json(response)["max_segments"] == 1
        assert stitched.containers["temp-videos"].uploads == []

    def test_rejects_too_many_bytes_before_staging(self, stitched, monkeypatch):
        monkeypatch.setenv("STITCH_MAX_BYTES", "1500")

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert response.status_code == 400
        assert _json(response)["total_bytes"] == 2000

    def test_rejects_when_temporary_storage_is_short(self, stitched, monkeypatch):
        monkeypatch.setattr(function_app.shutil, "disk_usage", lambda _path: SimpleNamespace(free=1024))

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert response.status_code == 503
        assert response.headers["Retry-After"] == str(function_app.STITCH_RETRY_AFTER_SECONDS)

    def test_rejects_when_every_stitch_slot_is_busy(self, stitched, monkeypatch):
        slots = threading.BoundedSemaphore(1)
        slots.acquire()
        monkeypatch.setattr(function_app, "_stitch_slots", slots)

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert response.status_code == 429
        assert stitched.containers["temp-videos"].uploads == []

    def test_slot_is_released_after_each_job(self, stitched, monkeypatch):
        monkeypatch.setattr(function_app, "_stitch_slots", threading.BoundedSemaphore(1))

        for _ in range(2):
            response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")
            assert response.status_code == 200

    def test_stops_at_the_request_deadline(self, stitched, monkeypatch):
        monkeypatch.setenv("STITCH_DEADLINE_SECONDS", "5")
        # The request starts at 0s; every later reading is past the 5s deadline
        readings = iter([0.0])
        monkeypatch.setattr(function_app.time, "monotonic", lambda: next(readings, 10.0))

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z", stitch="true", event_type="continuous")

        assert response.status_code == 504
        assert _json(response)["deadline_seconds"] == 5
        assert stitched.containers["temp-videos"].uploads == []


class TestStorageCredentials:
    def test_connection_string_doesnt_need_an_account_name(self, monkeypatch):
        monkeypatch.delenv("STORAGE_ACCOUNT_NAME", raising=False)
        monkeypatch.setenv(
            "STORAGE_CONNECTION_STRING",
            f"DefaultEndpointsProtocol=https;AccountName=account;AccountKey={ACCOUNT_KEY};EndpointSuffix=core.windows.net",
        )

        client, account_key = function_app._storage_client()

        assert client.account_name == "account"
        assert account_key == ACCOUNT_KEY

    def test_development_storage_connection_string_is_supported(self, monkeypatch):
        monkeypatch.setenv("STORAGE_CONNECTION_STRING", "UseDevelopmentStorage=true")

        client, account_key = function_app._storage_client()

        assert client.account_name == "devstoreaccount1"
        assert account_key

    def test_sas_connection_string_is_rejected_by_query_and_readiness(self, monkeypatch):
        monkeypatch.setenv(
            "STORAGE_CONNECTION_STRING",
            "BlobEndpoint=https://account.blob.core.windows.net/;SharedAccessSignature=sv=2024&sig=x",
        )

        response = query("2026-01-30T10:00:00Z", "2026-01-30T10:05:00Z")
        readiness = function_app.readiness_check(func.HttpRequest(method="GET", url="/api/ready", body=b""))

        assert response.status_code == 500
        assert _json(response) == {"error": "Storage connection not configured"}
        assert readiness.status_code == 503

    def test_managed_identity_needs_an_account_name(self, monkeypatch):
        monkeypatch.delenv("STORAGE_CONNECTION_STRING", raising=False)
        monkeypatch.delenv("STORAGE_ACCOUNT_NAME", raising=False)

        with pytest.raises(function_app.StorageConfigError):
            function_app._storage_client()


class RealPahoClient(mqtt.Client):
    """Real Paho client without a socket; PUBACKs are fed through Paho's own packet handler."""

    puback_reason = 0x00
    late = False

    def connect(self, host, port=1883, keepalive=60, bind_address="", bind_port=0, clean_start=3, properties=None):
        return mqtt.MQTT_ERR_SUCCESS

    def loop_start(self):
        self.on_connect(self, None, None, mqtt.ReasonCode(mqtt.PacketTypes.CONNACK, identifier=0), None)
        return mqtt.MQTT_ERR_SUCCESS

    def loop_stop(self):
        return mqtt.MQTT_ERR_SUCCESS

    def disconnect(self, reasoncode=None, properties=None):
        return mqtt.MQTT_ERR_SUCCESS

    def publish(self, topic, payload=None, qos=0, retain=False, properties=None):
        info = super().publish(topic, payload, qos, retain, properties)
        info.rc = mqtt.MQTT_ERR_SUCCESS

        def deliver():
            self._in_packet = {"remaining_length": 3, "packet": struct.pack("!HB", info.mid, self.puback_reason)}
            self._handle_pubackcomp("PUBACK")

        if self.late:
            threading.Timer(0.05, deliver).start()
        else:
            deliver()
        return info


class TestPahoPuback:
    @pytest.fixture
    def paho(self, monkeypatch):
        credential = MagicMock()
        credential.get_token.return_value = SimpleNamespace(token="header.payload.signature")  # noqa: S106
        monkeypatch.setattr(function_app, "ManagedIdentityCredential", MagicMock(return_value=credential))
        monkeypatch.setattr(function_app.mqtt, "Client", RealPahoClient)
        monkeypatch.setattr(function_app, "MQTT_TIMEOUT_SECONDS", 1)
        RealPahoClient.puback_reason = 0x00
        RealPahoClient.late = False
        return RealPahoClient

    @pytest.mark.parametrize("late", [False, True])
    def test_not_authorized_puback_is_rejected(self, paho, late):
        paho.puback_reason = 0x87
        paho.late = late

        with pytest.raises(PermissionError, match="Not authorized"):
            function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")

    @pytest.mark.parametrize("late", [False, True])
    def test_success_puback_is_accepted(self, paho, late):
        paho.late = late

        function_app._publish_mqtt_trigger("host", "alerts/trigger/camera-01", "{}")
