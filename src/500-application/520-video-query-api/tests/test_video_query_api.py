#!/usr/bin/env python3
"""
Video Query API Integration Tests.

Tests the deployed Azure Function API for:
- Segment queries with metadata enrichment
- Triggered recording detection
- Event type filtering
- Enhanced stitching with gap detection
- Empty results handling
- API latency requirements
"""

import os
import time
from datetime import UTC, datetime, timedelta

import pytest
import requests

# API Configuration - must be set via environment variables
API_ENDPOINT = os.getenv("VIDEO_QUERY_API_ENDPOINT")
API_CODE = os.getenv("VIDEO_QUERY_API_CODE")

# Test cameras
CONTINUOUS_CAMERA = os.getenv("TEST_CONTINUOUS_CAMERA", "pmn-camera-01")
TRIGGERED_CAMERA = os.getenv("TEST_TRIGGERED_CAMERA", "pmn-camera-01-triggered")


def api_url(params: dict) -> str:
    """Build API URL with query parameters."""
    params["code"] = API_CODE
    query = "&".join(f"{k}={v}" for k, v in params.items())
    return f"{API_ENDPOINT}/api/video?{query}"


def get_recent_timerange(hours: int = 1) -> tuple[str, str]:
    """Get ISO timestamps for recent time range."""
    end = datetime.now(UTC)
    start = end - timedelta(hours=hours)
    return start.strftime("%Y-%m-%dT%H:%M:%SZ"), end.strftime("%Y-%m-%dT%H:%M:%SZ")


@pytest.fixture(scope="module")
def api_available():
    """Check if API is available before running tests."""
    if not API_ENDPOINT or not API_CODE:
        pytest.skip(
            "API credentials not configured. Set VIDEO_QUERY_API_ENDPOINT and "
            "VIDEO_QUERY_API_CODE environment variables."
        )
    try:
        response = requests.get(f"{API_ENDPOINT}/api/health", timeout=10)
        if response.status_code != 200:
            pytest.skip(f"API health check failed: {response.status_code}")
    except requests.RequestException as e:
        pytest.skip(f"API not available: {e}")


@pytest.mark.integration
class TestSegmentQuery:
    """Tests for basic segment query functionality."""

    def test_segment_query_returns_segments(self, api_available):
        """Segment query must return segments array with metadata."""
        start, end = get_recent_timerange(hours=2)
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )

        assert response.status_code == 200
        data = response.json()
        assert "segments" in data
        assert "total_segments" in data
        assert data["stitched"] is False

    def test_segment_has_required_fields(self, api_available):
        """Each segment must have required base fields."""
        start, end = get_recent_timerange(hours=2)
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )

        data = response.json()
        if data["total_segments"] > 0:
            segment = data["segments"][0]
            assert "url" in segment
            assert "name" in segment
            assert "timestamp" in segment
            assert "size_bytes" in segment
            assert "recording_type" in segment


@pytest.mark.integration
class TestMetadataEnrichment:
    """Tests for JSON metadata enrichment feature."""

    def test_segment_has_metadata_fields(self, api_available):
        """Segments must include metadata-enriched fields when available."""
        start, end = get_recent_timerange(hours=2)
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )

        data = response.json()
        if data["total_segments"] > 0:
            segment = data["segments"][0]
            # These fields come from JSON metadata sidecar files
            assert "duration_seconds" in segment
            assert "location" in segment
            assert "segment_start" in segment
            assert "segment_end" in segment

    def test_metadata_has_precise_timestamps(self, api_available):
        """Metadata timestamps must include nanosecond precision."""
        start, end = get_recent_timerange(hours=2)
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )

        data = response.json()
        if data["total_segments"] > 0:
            segment = data["segments"][0]
            if segment.get("segment_start"):
                # Should have format like: 2026-02-04T18:03:03.170549170+00:00
                assert "." in segment["segment_start"]
                assert "+" in segment["segment_start"] or "Z" in segment["segment_start"]


@pytest.mark.integration
class TestRecordingTypeDetection:
    """Tests for recording type detection (continuous vs triggered)."""

    def test_continuous_recording_type(self, api_available):
        """Continuous recordings must have recording_type='continuous'."""
        start, end = get_recent_timerange(hours=2)
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )

        data = response.json()
        if data["total_segments"] > 0:
            segment = data["segments"][0]
            assert segment["recording_type"] == "continuous"
            assert segment["event_type"] is None

    def test_triggered_recording_type(self, api_available):
        """Triggered recordings must have recording_type='triggered' and event_type."""
        # Use a wider time range to find triggered recordings
        end = datetime.now(UTC)
        start = end - timedelta(days=1)
        start_str = start.strftime("%Y-%m-%dT%H:%M:%SZ")
        end_str = end.strftime("%Y-%m-%dT%H:%M:%SZ")

        response = requests.get(
            api_url({"camera": TRIGGERED_CAMERA, "start": start_str, "end": end_str}),
            timeout=30
        )

        data = response.json()
        if data["total_segments"] > 0:
            segment = data["segments"][0]
            assert segment["recording_type"] == "triggered"
            assert segment["event_type"] is not None
            assert segment["event_type"] in ["alert", "analytics_disabled", "motion"]


@pytest.mark.integration
class TestEventTypeFiltering:
    """Tests for event_type query parameter filtering."""

    def test_filter_by_event_type_alert(self, api_available):
        """Filter by event_type=alert must return only alert segments."""
        end = datetime.now(UTC)
        start = end - timedelta(days=1)
        start_str = start.strftime("%Y-%m-%dT%H:%M:%SZ")
        end_str = end.strftime("%Y-%m-%dT%H:%M:%SZ")

        response = requests.get(
            api_url({
                "camera": TRIGGERED_CAMERA,
                "start": start_str,
                "end": end_str,
                "event_type": "alert"
            }),
            timeout=30
        )

        data = response.json()
        assert data["event_type_filter"] == "alert"
        for segment in data["segments"]:
            assert segment["event_type"] == "alert"

    def test_filter_by_nonexistent_event_type(self, api_available):
        """Filter by non-matching event_type must return empty results."""
        start, end = get_recent_timerange(hours=1)
        response = requests.get(
            api_url({
                "camera": CONTINUOUS_CAMERA,
                "start": start,
                "end": end,
                "event_type": "nonexistent_type"
            }),
            timeout=30
        )

        data = response.json()
        assert data["total_segments"] == 0


@pytest.mark.integration
class TestEnhancedStitch:
    """Tests for enhanced stitching with metadata."""

    def test_stitch_returns_video_url(self, api_available):
        """Stitch=true must return single video_url."""
        start, end = get_recent_timerange(hours=1)
        response = requests.get(
            api_url({
                "camera": CONTINUOUS_CAMERA,
                "start": start,
                "end": end,
                "stitch": "true"
            }),
            timeout=180  # Stitching takes longer
        )

        data = response.json()
        if "error" not in data:
            assert data["stitched"] is True
            assert "video_url" in data
            assert "segment_count" in data

    def test_stitch_includes_metadata_metrics(self, api_available):
        """Stitched response must include metadata-derived metrics."""
        start, end = get_recent_timerange(hours=1)
        response = requests.get(
            api_url({
                "camera": CONTINUOUS_CAMERA,
                "start": start,
                "end": end,
                "stitch": "true"
            }),
            timeout=180
        )

        data = response.json()
        if "error" not in data and data.get("segment_count", 0) > 0:
            # These fields come from metadata enrichment
            assert "actual_duration_seconds" in data
            assert "earliest_segment_start" in data
            assert "latest_segment_end" in data
            assert "locations" in data
            assert "metadata_coverage" in data

    def test_stitch_detects_gaps(self, api_available):
        """Stitched response must report gaps when present."""
        # Use longer timeframe to increase chance of gaps
        end = datetime.now(UTC)
        start = end - timedelta(hours=2)
        start_str = start.strftime("%Y-%m-%dT%H:%M:%SZ")
        end_str = end.strftime("%Y-%m-%dT%H:%M:%SZ")

        response = requests.get(
            api_url({
                "camera": CONTINUOUS_CAMERA,
                "start": start_str,
                "end": end_str,
                "stitch": "true"
            }),
            timeout=180
        )

        data = response.json()
        if "error" not in data:
            # Gap fields should be present (may be null/0 if no gaps)
            if data.get("gap_count"):
                assert "gaps" in data
                assert "total_gap_seconds" in data
                assert len(data["gaps"]) == data["gap_count"]
                for gap in data["gaps"]:
                    assert "after_segment" in gap
                    assert "before_segment" in gap
                    assert "gap_seconds" in gap


@pytest.mark.integration
class TestEmptyResults:
    """Tests for empty results handling."""

    def test_empty_results_return_200(self, api_available):
        """Empty results must return HTTP 200, not 404."""
        response = requests.get(
            api_url({
                "camera": "nonexistent-camera-xyz",
                "start": "2026-01-01T00:00:00Z",
                "end": "2026-01-01T00:05:00Z"
            }),
            timeout=30
        )

        assert response.status_code == 200
        data = response.json()
        assert data["segments"] == []
        assert data["total_segments"] == 0
        assert "message" in data


@pytest.mark.integration
class TestAPILatency:
    """Tests for API response time requirements."""

    def test_segment_query_latency_under_2_seconds(self, api_available):
        """Segment query must complete in under 2 seconds."""
        start, end = get_recent_timerange(hours=1)

        start_time = time.time()
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": start, "end": end}),
            timeout=30
        )
        elapsed = time.time() - start_time

        assert response.status_code == 200
        assert elapsed < 2.0, f"Query took {elapsed:.2f}s, expected < 2.0s"


@pytest.mark.integration
class TestParameterValidation:
    """Tests for parameter validation."""

    def test_missing_camera_returns_400(self, api_available):
        """Missing camera parameter must return 400."""
        response = requests.get(
            api_url({"start": "2026-01-01T00:00:00Z", "end": "2026-01-01T01:00:00Z"}),
            timeout=30
        )

        assert response.status_code == 400

    def test_missing_start_returns_400(self, api_available):
        """Missing start parameter must return 400."""
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "end": "2026-01-01T01:00:00Z"}),
            timeout=30
        )

        assert response.status_code == 400

    def test_missing_end_returns_400(self, api_available):
        """Missing end parameter must return 400."""
        response = requests.get(
            api_url({"camera": CONTINUOUS_CAMERA, "start": "2026-01-01T00:00:00Z"}),
            timeout=30
        )

        assert response.status_code == 400

    def test_duration_exceeds_24_hours_returns_400(self, api_available):
        """Query duration > 24 hours must return 400."""
        response = requests.get(
            api_url({
                "camera": CONTINUOUS_CAMERA,
                "start": "2026-01-01T00:00:00Z",
                "end": "2026-01-03T00:00:00Z"  # 48 hours
            }),
            timeout=30
        )

        assert response.status_code == 400
        data = response.json()
        assert "24 hours" in data.get("error", "").lower() or "duration" in data.get("error", "").lower()
