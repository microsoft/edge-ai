#!/usr/bin/env python3
"""
Video Query API deployed tests.

Seeds recordings in the layout the 503 media capture service writes, then
exercises a deployed API end to end: discovery, overlap, filtering, gaps,
and a downloaded stitched result.

The suite runs when VIDEO_QUERY_API_ENDPOINT is set. It then also requires:

- VIDEO_QUERY_API_CODE: Function key for the API
- VIDEO_QUERY_TEST_STORAGE_CONNECTION_STRING, or VIDEO_QUERY_TEST_STORAGE_ACCOUNT
  with an identity that can write blobs: the storage account the API reads
- ffmpeg and ffprobe on PATH, to generate and inspect video

Optional: VIDEO_RECORDINGS_CONTAINER and VIDEO_BLOB_PREFIX, which must match
the API's settings. A configured but unreachable deployment fails the suite
instead of skipping it. Seeded blobs are deleted afterwards.
"""

import json
import os
import shutil
import subprocess
import time
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest
import requests

API_ENDPOINT = os.getenv("VIDEO_QUERY_API_ENDPOINT", "").rstrip("/")
API_CODE = os.getenv("VIDEO_QUERY_API_CODE")
RECORDINGS_CONTAINER = os.getenv("VIDEO_RECORDINGS_CONTAINER", "video-recordings")
BLOB_PREFIX = os.getenv("VIDEO_BLOB_PREFIX", "")

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not API_ENDPOINT, reason="VIDEO_QUERY_API_ENDPOINT isn't set"),
]

# Seeded footage: continuous segments 10:00:00-10:00:10 and 10:00:10-10:00:20,
# a 20-second gap, then 10:00:40-10:00:50, plus an alert clip written at 10:00:15
BASE = datetime(2026, 1, 30, 10, 0, 0, tzinfo=UTC)
SEGMENT_SECONDS = 10
SEGMENT_OFFSETS = (0, 10, 40)
ALERT_OFFSET = 15
GAP_SECONDS = 20


def _iso(moment: datetime) -> str:
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ")


def _blob_path(camera: str, moment: datetime, file_name: str) -> str:
    path = f"{camera}/{moment:%Y/%m/%d/%H}/{file_name}"
    return f"{BLOB_PREFIX}/{path}" if BLOB_PREFIX else path


def _generate_clip(path: Path, container_format: str) -> None:
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "lavfi"]
        + ["-i", f"testsrc=size=640x360:rate=15:duration={SEGMENT_SECONDS}"]
        + ["-c:v", "libx264", "-preset", "ultrafast", "-g", "30", "-pix_fmt", "yuv420p"]
        + ["-f", container_format, "-y", str(path)],
        check=True,
        timeout=60,
    )


def _probe_seconds(path: Path) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True,
        capture_output=True,
        text=True,
        timeout=60,
    )
    return float(result.stdout.strip())


def _container_client():
    from azure.storage.blob import BlobServiceClient

    connection_string = os.getenv("VIDEO_QUERY_TEST_STORAGE_CONNECTION_STRING")
    account = os.getenv("VIDEO_QUERY_TEST_STORAGE_ACCOUNT")
    if connection_string:
        service = BlobServiceClient.from_connection_string(connection_string)
    elif account:
        from azure.identity import DefaultAzureCredential

        service = BlobServiceClient(
            account_url=f"https://{account}.blob.core.windows.net", credential=DefaultAzureCredential()
        )
    else:
        pytest.fail("Set VIDEO_QUERY_TEST_STORAGE_CONNECTION_STRING or VIDEO_QUERY_TEST_STORAGE_ACCOUNT to seed data")
    return service.get_container_client(RECORDINGS_CONTAINER)


@pytest.fixture(scope="module")
def api():
    """The configured deployment; fails rather than skips when it's unusable."""
    if not API_CODE:
        pytest.fail("VIDEO_QUERY_API_ENDPOINT is set but VIDEO_QUERY_API_CODE isn't")
    for tool in ("ffmpeg", "ffprobe"):
        if not shutil.which(tool):
            pytest.fail(f"{tool} is required to seed and inspect test video")
    try:
        health = requests.get(f"{API_ENDPOINT}/api/health", timeout=10)
    except requests.RequestException as e:
        pytest.fail(f"Configured API isn't reachable: {e}")
    assert health.status_code == 200, f"Health check returned {health.status_code}"
    return API_ENDPOINT


@pytest.fixture(scope="module")
def seeded(api, tmp_path_factory):
    """Upload producer-shaped recordings for a unique camera; delete them afterwards."""
    camera = f"it-{uuid.uuid4().hex[:8]}"
    work = tmp_path_factory.mktemp("seed")
    segment_file = work / "segment.mp4"
    alert_file = work / "alert.mkv"
    _generate_clip(segment_file, "mp4")
    _generate_clip(alert_file, "matroska")

    container = _container_client()
    names = {"continuous": [], "alert": None}
    uploaded = []
    try:
        for offset in SEGMENT_OFFSETS:
            start = BASE + timedelta(seconds=offset)
            name = _blob_path(camera, start, f"segment_{start:%Y-%m-%dT%H:%M:%SZ}_{camera}.mp4")
            sidecar = {
                "camera_id": camera,
                "location": "integration-test",
                "segment_start": start.isoformat(),
                "segment_end": (start + timedelta(seconds=SEGMENT_SECONDS)).isoformat(),
                "duration_seconds": SEGMENT_SECONDS,
                "file_name": name.rsplit("/", 1)[1],
            }
            with open(segment_file, "rb") as data:
                container.upload_blob(name, data, overwrite=True)
            uploaded.append(name)
            sidecar_name = name.rsplit(".", 1)[0] + ".json"
            container.upload_blob(sidecar_name, json.dumps(sidecar), overwrite=True)
            uploaded.append(sidecar_name)
            names["continuous"].append(name)

        alert_time = BASE + timedelta(seconds=ALERT_OFFSET)
        alert_name = _blob_path(camera, alert_time, f"{alert_time:%Y-%m-%d_%H%M%S}_segment_alert_event_id_42.mkv")
        with open(alert_file, "rb") as data:
            container.upload_blob(alert_name, data, overwrite=True)
        uploaded.append(alert_name)
        names["alert"] = alert_name

        yield {"camera": camera, "segment_bytes": segment_file.stat().st_size, **names}
    finally:
        for name in uploaded:
            container.delete_blob(name)


def get(api_base: str, params: dict, timeout: int = 60) -> requests.Response:
    return requests.get(f"{api_base}/api/video", params={**params, "code": API_CODE}, timeout=timeout)


class TestReadiness:
    def test_ready_reports_storage_reachable(self, api):
        response = requests.get(f"{api}/api/ready", params={"code": API_CODE}, timeout=30)

        assert response.status_code == 200
        assert response.json() == {"status": "ready"}


class TestSegmentQuery:
    def test_returns_every_seeded_recording_with_downloadable_urls(self, api, seeded):
        response = get(api, {"camera": seeded["camera"], "start": _iso(BASE), "end": _iso(BASE + timedelta(minutes=1))})

        assert response.status_code == 200, response.text
        data = response.json()
        assert data["stitched"] is False
        assert [s["name"] for s in data["segments"]] == [
            seeded["continuous"][0],
            seeded["continuous"][1],
            seeded["alert"],
            seeded["continuous"][2],
        ]

        first = data["segments"][0]
        assert first["recording_type"] == "continuous"
        assert first["timing"] == "metadata"
        assert first["location"] == "integration-test"
        assert first["duration_seconds"] == SEGMENT_SECONDS
        download = requests.get(first["url"], timeout=60)
        assert download.status_code == 200
        assert len(download.content) == seeded["segment_bytes"]

    def test_returns_a_recording_that_started_before_the_window(self, api, seeded):
        window_start = BASE + timedelta(seconds=5)
        response = get(
            api,
            {"camera": seeded["camera"], "start": _iso(window_start), "end": _iso(window_start + timedelta(seconds=1))},
        )

        assert response.status_code == 200, response.text
        assert [s["name"] for s in response.json()["segments"]] == [seeded["continuous"][0]]

    def test_filters_by_event_type(self, api, seeded):
        window = {"camera": seeded["camera"], "start": _iso(BASE), "end": _iso(BASE + timedelta(minutes=1))}

        alerts = get(api, {**window, "event_type": "alert"})
        continuous = get(api, {**window, "event_type": "continuous"})

        assert alerts.status_code == continuous.status_code == 200
        alert_segments = alerts.json()["segments"]
        assert [s["name"] for s in alert_segments] == [seeded["alert"]]
        assert alert_segments[0]["recording_type"] == "triggered"
        assert alert_segments[0]["event_type"] == "alert"
        assert alert_segments[0]["timing"] == "filename"
        assert [s["name"] for s in continuous.json()["segments"]] == seeded["continuous"]

    def test_unknown_camera_returns_empty_200(self, api):
        response = get(
            api,
            {
                "camera": f"it-none-{uuid.uuid4().hex[:8]}",
                "start": _iso(BASE),
                "end": _iso(BASE + timedelta(minutes=5)),
            },
        )

        assert response.status_code == 200, response.text
        data = response.json()
        assert data["segments"] == []
        assert data["total_segments"] == 0

    def test_segment_query_latency_under_2_seconds(self, api, seeded):
        started = time.monotonic()
        response = get(api, {"camera": seeded["camera"], "start": _iso(BASE), "end": _iso(BASE + timedelta(minutes=1))})
        elapsed = time.monotonic() - started

        assert response.status_code == 200, response.text
        assert elapsed < 2.0, f"Query took {elapsed:.2f}s, expected < 2.0s"


class TestStitch:
    def test_stitched_video_contains_every_segment_and_reports_the_gap(self, api, seeded, tmp_path):
        response = get(
            api,
            {
                "camera": seeded["camera"],
                "start": _iso(BASE),
                "end": _iso(BASE + timedelta(minutes=1)),
                "event_type": "continuous",
                "stitch": "true",
            },
            timeout=230,
        )

        assert response.status_code == 200, response.text
        data = response.json()
        assert data["stitched"] is True
        assert data["trimmed"] is False
        assert data["segment_count"] == len(SEGMENT_OFFSETS)
        assert data["gap_count"] == 1
        assert data["gaps"][0]["gap_seconds"] == GAP_SECONDS
        assert data["earliest_segment_start"] == BASE.isoformat()
        assert data["latest_segment_end"] == (BASE + timedelta(seconds=50)).isoformat()
        assert data["actual_duration_seconds"] == SEGMENT_SECONDS * len(SEGMENT_OFFSETS)

        download = requests.get(data["video_url"], timeout=120)
        assert download.status_code == 200
        stitched = tmp_path / "stitched.mp4"
        stitched.write_bytes(download.content)
        assert download.content[4:8] == b"ftyp"
        assert _probe_seconds(stitched) == pytest.approx(SEGMENT_SECONDS * len(SEGMENT_OFFSETS), abs=1.0)

    def test_mixed_recording_types_are_rejected(self, api, seeded):
        response = get(
            api,
            {
                "camera": seeded["camera"],
                "start": _iso(BASE),
                "end": _iso(BASE + timedelta(minutes=1)),
                "stitch": "true",
            },
        )

        assert response.status_code == 400, response.text
        assert response.json()["recording_types"] == ["continuous", "triggered"]

    def test_window_over_the_stitch_limit_is_rejected(self, api, seeded):
        response = get(
            api,
            {"camera": seeded["camera"], "start": _iso(BASE), "end": _iso(BASE + timedelta(hours=2)), "stitch": "true"},
        )

        assert response.status_code == 400, response.text
        assert response.json()["error"] == "Stitched query window too long"


class TestParameterValidation:
    @pytest.mark.parametrize(
        "params",
        [
            {"start": "2026-01-01T00:00:00Z", "end": "2026-01-01T01:00:00Z"},
            {"camera": "camera-01", "end": "2026-01-01T01:00:00Z"},
            {"camera": "camera-01", "start": "2026-01-01T00:00:00Z"},
            {"camera": "camera-01", "start": "2026-01-01T00:00:00Z", "end": "2026-01-03T00:00:00Z"},
            {"camera": "camera-01' OR '1'='1", "start": "2026-01-01T00:00:00Z", "end": "2026-01-01T01:00:00Z"},
        ],
    )
    def test_invalid_requests_return_400(self, api, params):
        response = get(api, params)

        assert response.status_code == 400, response.text
        assert "error" in response.json()
