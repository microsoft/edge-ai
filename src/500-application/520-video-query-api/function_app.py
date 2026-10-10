"""
Video Query API - Azure Function for time-based video queries.

Provides REST endpoint for querying and retrieving video segments from
continuous camera recordings stored in Azure Blob Storage.

Recordings follow the 503 media capture service layout,
`{camera}/{YYYY}/{MM}/{DD}/{HH}/{file}`, with an optional JSON sidecar that
holds the footage interval (`segment_start`, `segment_end`).

Supports filtering by event_type:
- continuous: Regular continuous recording segments
- triggered: MQTT-triggered capture segments (alerts, analytics events)
- <specific>: Filter by specific event type (alert, analytics_disabled, etc.)
"""

import json
import logging
import os
import re
import shutil
import ssl
import subprocess
import tempfile
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Literal

import azure.functions as func
import paho.mqtt.client as mqtt
from azure.core.exceptions import AzureError, ResourceNotFoundError
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import (
    BlobSasPermissions,
    BlobServiceClient,
    ContainerClient,
    UserDelegationKey,
    generate_blob_sas,
)
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.properties import Properties

app = func.FunctionApp()

# Configure logging
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)

# Trigger endpoint configuration. The rate limit is kept in memory per
# function instance, so it isn't shared across scaled-out instances or restarts.
_trigger_rate_limits: dict[str, float] = {}
TRIGGER_RATE_LIMIT_SECONDS = 30
TRIGGER_TOPIC_PREFIX = "alerts/trigger"
EVENT_GRID_MQTT_SCOPE = "https://eventgrid.azure.net/.default"
MQTT_TIMEOUT_SECONDS = 10

# Stitching runs inside the HTTP request, which the Azure load balancer ends
# after 230 seconds, so stitch jobs are bounded before any data is staged.
DEFAULT_STITCH_MAX_SECONDS = 3600
DEFAULT_STITCH_MAX_SEGMENTS = 120
DEFAULT_STITCH_MAX_BYTES = 2 * 1024**3
DEFAULT_STITCH_DEADLINE_SECONDS = 200
DEFAULT_STITCH_MAX_CONCURRENT = 1
STITCH_DISK_HEADROOM_BYTES = 64 * 1024**2
STITCH_RETRY_AFTER_SECONDS = 30
METADATA_FETCH_WORKERS = 8
METADATA_MAX_BYTES = 64 * 1024

# A recording can start before the query window and still overlap it, so
# discovery also lists earlier hours. The default covers the longest 503
# segment (1 hour) plus its capture grace period.
DEFAULT_SEGMENT_LOOKBACK_SECONDS = 3900

VIDEO_EXTENSIONS = (".mp4", ".mkv", ".avi", ".mov")

# Allowed camera_id format: alphanumeric, underscore, hyphen. Keeps camera IDs
# from escaping their blob prefix or MQTT topic level.
CAMERA_ID_PATTERN = re.compile(r"^[a-zA-Z0-9_\-]+$")


class DiscoveryError(Exception):
    """Listing or metadata retrieval failed, so results would be incomplete."""


class StorageConfigError(Exception):
    """Storage settings are missing or can't sign SAS URLs."""


class StitchDeadlineError(Exception):
    """A stitch job ran past its request deadline."""


def _positive_int_env(name: str, default: int) -> int:
    """Return a positive integer setting, or `default` when unset or invalid."""
    try:
        value = int(os.getenv(name, str(default)))
    except ValueError:
        return default
    return value if value > 0 else default


# Per-instance limit; each instance stages stitch jobs on its own disk.
_stitch_slots = threading.BoundedSemaphore(_positive_int_env("STITCH_MAX_CONCURRENT", DEFAULT_STITCH_MAX_CONCURRENT))


def as_utc(value: object) -> datetime | None:
    """Normalize a timestamp to an aware UTC datetime.

    Strings are parsed as ISO 8601. Values without an offset are treated as
    UTC. Anything else, including unparseable strings, returns None.
    """
    if isinstance(value, str):
        try:
            value = datetime.fromisoformat(value)
        except ValueError:
            return None
    if not isinstance(value, datetime):
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def _storage_client() -> tuple[BlobServiceClient, str | None]:
    """Return a blob service client and, for connection strings, the account key.

    STORAGE_CONNECTION_STRING takes precedence and must carry an account key
    (AccountKey, or UseDevelopmentStorage=true for Azurite), which signs the
    SAS URLs; SAS-token connection strings are rejected. Otherwise
    STORAGE_ACCOUNT_NAME selects the account, accessed with the managed
    identity and user delegation SAS.
    """
    connection_string = os.getenv("STORAGE_CONNECTION_STRING")
    if connection_string:
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        account_key = getattr(blob_service_client.credential, "account_key", None)
        if not account_key:
            raise StorageConfigError("STORAGE_CONNECTION_STRING must include an account key to sign SAS URLs")
        return blob_service_client, account_key

    storage_account_name = os.getenv("STORAGE_ACCOUNT_NAME")
    if not storage_account_name:
        raise StorageConfigError("Set STORAGE_ACCOUNT_NAME or STORAGE_CONNECTION_STRING")
    account_url = f"https://{storage_account_name}.blob.core.windows.net"
    return BlobServiceClient(account_url=account_url, credential=_managed_identity_credential()), None


def _allowed_trigger_cameras() -> set[str]:
    """Return trigger-enabled camera IDs from TRIGGER_ALLOWED_CAMERAS.

    The setting is a comma-separated list. Entries that don't match
    CAMERA_ID_PATTERN are ignored. An empty or missing setting disables
    the trigger endpoint.
    """
    raw = os.getenv("TRIGGER_ALLOWED_CAMERAS", "")
    return {
        camera
        for camera in (entry.strip() for entry in raw.split(","))
        if camera and CAMERA_ID_PATTERN.fullmatch(camera)
    }


def _managed_identity_credential() -> ManagedIdentityCredential:
    """Return a managed identity credential.

    Uses the user-assigned identity named by AZURE_CLIENT_ID when it's set,
    otherwise the system-assigned identity.
    """
    return ManagedIdentityCredential(client_id=os.environ.get("AZURE_CLIENT_ID") or None)


def _publish_mqtt_trigger(hostname: str, topic: str, payload: str) -> None:
    """Publish a QoS 1 message to an Event Grid namespace over MQTT v5.

    Authenticates with a Microsoft Entra token through the MQTT v5 enhanced
    authentication fields (OAUTH2-JWT). Each call connects with a unique
    client ID, so concurrent requests and scaled-out instances don't replace
    each other's sessions. Raises when the connection is refused, the broker
    doesn't acknowledge the publish within the timeout, or the PUBACK carries
    a failure reason code such as Not authorized.
    """
    token = _managed_identity_credential().get_token(EVENT_GRID_MQTT_SCOPE).token
    client_id = f"{os.environ.get('MQTT_CLIENT_ID', 'video-query-trigger')}-{uuid.uuid4().hex[:12]}"

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=client_id,
        protocol=mqtt.MQTTv5,
    )
    client.tls_set(tls_version=ssl.PROTOCOL_TLS_CLIENT)

    connect_properties = Properties(PacketTypes.CONNECT)
    connect_properties.AuthenticationMethod = "OAUTH2-JWT"
    connect_properties.AuthenticationData = token.encode()

    connected = threading.Event()
    connect_failure: list[str] = []
    # PUBACK reason codes keyed by message ID. The callback can run before
    # publish() returns, so acknowledgments are recorded for any ID.
    acknowledgments: dict[int, object] = {}
    acknowledged = threading.Condition()

    def on_connect(_client, _userdata, _flags, reason_code, _properties):
        if reason_code.is_failure:
            connect_failure.append(str(reason_code))
        connected.set()

    def on_publish(_client, _userdata, mid, reason_code, _properties):
        with acknowledged:
            acknowledgments[mid] = reason_code
            acknowledged.notify_all()

    client.on_connect = on_connect
    client.on_publish = on_publish
    client.connect(hostname, port=8883, properties=connect_properties)
    client.loop_start()
    try:
        if not connected.wait(MQTT_TIMEOUT_SECONDS):
            raise TimeoutError("MQTT connection timed out")
        if connect_failure:
            raise ConnectionError(f"MQTT connection refused: {connect_failure[0]}")

        result = client.publish(topic, payload, qos=1)
        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            raise ConnectionError(f"MQTT publish failed: {mqtt.error_string(result.rc)}")
        with acknowledged:
            if not acknowledged.wait_for(lambda: result.mid in acknowledgments, timeout=MQTT_TIMEOUT_SECONDS):
                raise TimeoutError("MQTT publish wasn't acknowledged")
            reason_code = acknowledgments[result.mid]
        if reason_code.is_failure:
            raise PermissionError(f"MQTT publish rejected: {reason_code}")
    finally:
        client.disconnect()
        client.loop_stop()


@app.route(route="health", auth_level=func.AuthLevel.ANONYMOUS)
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Liveness probe. Performs no storage access and returns no configuration details."""
    return func.HttpResponse(json.dumps({"status": "healthy"}), status_code=200, mimetype="application/json")


@app.route(route="ready", auth_level=func.AuthLevel.FUNCTION)
def readiness_check(req: func.HttpRequest) -> func.HttpResponse:
    """Readiness probe that verifies blob storage connectivity.

    Requires a function key. The response reports only the readiness state;
    failure details are logged server-side and never returned to the caller.
    """
    container_name = os.getenv("VIDEO_RECORDINGS_CONTAINER", "video-recordings")

    try:
        blob_service_client, _account_key = _storage_client()
        container = blob_service_client.get_container_client(container_name)
        container.get_container_properties()
    except Exception:
        logger.exception("Readiness check failed")
        return func.HttpResponse(json.dumps({"status": "not_ready"}), status_code=503, mimetype="application/json")

    return func.HttpResponse(json.dumps({"status": "ready"}), status_code=200, mimetype="application/json")


def parse_timestamp_from_blob_name(blob_name: str) -> datetime | None:
    """
    Parse timestamp from blob name for both continuous and triggered recordings.

    Supported formats:
        Continuous: {camera}/{YYYY}/{MM}/{DD}/{HH}/segment_{timestamp}_{camera}.mp4
            Example: segment_2026-01-30T19:05:44Z_camera-01.mp4

        Triggered: {camera}/{YYYY}/{MM}/{DD}/{HH}/{timestamp}_{event_type}_id_{id}.mkv
            Example: 2026-01-30_190544_alert_event_id_12345.mkv

    Args:
        blob_name: Blob path

    Returns:
        Datetime object (timezone-naive UTC) or None if parsing fails
    """
    try:
        parts = blob_name.split("/")
        filename = parts[-1]

        # Try continuous format: segment_{ISO8601_timestamp}_{camera}.mp4
        if filename.startswith("segment_"):
            timestamp_str = filename.split("_")[1]
            if timestamp_str.endswith("Z"):
                timestamp_str = timestamp_str[:-1]
            dt = datetime.fromisoformat(timestamp_str)
            if dt.tzinfo is not None:
                dt = dt.replace(tzinfo=None)
            return dt

        # Try triggered format: {YYYY-MM-DD}_{HHMMSS}_...
        # Example: 2026-01-30_190544_alert_event_id_12345.mkv
        match = re.match(r"^(\d{4}-\d{2}-\d{2})_(\d{6})_", filename)
        if match:
            date_str = match.group(1)
            time_str = match.group(2)
            timestamp_str = f"{date_str}T{time_str[:2]}:{time_str[2:4]}:{time_str[4:6]}"
            return datetime.fromisoformat(timestamp_str)

        # Fallback: try to extract timestamp from path hierarchy
        # Path format: {camera}/{YYYY}/{MM}/{DD}/{HH}/...
        if len(parts) >= 6:
            try:
                year = int(parts[-5])
                month = int(parts[-4])
                day = int(parts[-3])
                hour = int(parts[-2])
                return datetime(year, month, day, hour, 0, 0)
            except (ValueError, IndexError):
                pass

        return None
    except (IndexError, ValueError) as e:
        logger.warning(f"Failed to parse timestamp from blob name {blob_name}: {e}")
        return None


def fetch_segment_metadata(container: ContainerClient, video_blob_name: str) -> dict | None:
    """
    Fetch companion JSON metadata for a video segment.

    A missing, oversized, or malformed sidecar returns None. Authorization and
    transport failures raise DiscoveryError, so they aren't mistaken for a
    segment without metadata.

    Args:
        container: Blob container client
        video_blob_name: Path to the video blob (e.g., "camera/2026/02/04/18/segment_xxx.mp4")

    Returns:
        Dictionary with metadata fields or None if not available
    """
    json_blob_name = video_blob_name.rsplit(".", 1)[0] + ".json"

    try:
        downloader = container.get_blob_client(json_blob_name).download_blob()
        if downloader.size > METADATA_MAX_BYTES:
            logger.warning(f"Ignoring metadata for {video_blob_name}: {downloader.size} bytes exceeds the limit")
            return None
        metadata = json.loads(downloader.readall().decode("utf-8"))
    except ResourceNotFoundError:
        logger.debug(f"No metadata found for {video_blob_name}")
        return None
    except ValueError:
        logger.warning(f"Ignoring malformed metadata for {video_blob_name}")
        return None
    except AzureError as e:
        raise DiscoveryError(f"Metadata retrieval failed for {video_blob_name}") from e

    return metadata if isinstance(metadata, dict) else None


def fetch_metadata_for_segments(container: ContainerClient, segments: list[dict]) -> list[dict | None]:
    """Fetch companion metadata for each segment concurrently, preserving order."""
    if not segments:
        return []
    with ThreadPoolExecutor(max_workers=min(METADATA_FETCH_WORKERS, len(segments))) as executor:
        return list(executor.map(lambda segment: fetch_segment_metadata(container, segment["name"]), segments))


def detect_recording_type(blob_name: str) -> tuple[Literal["continuous", "triggered"], str | None]:
    """
    Detect whether a blob is a continuous or triggered recording.

    Continuous recordings follow the pattern:
        {camera}/{YYYY}/{MM}/{DD}/{HH}/segment_{timestamp}_{camera}.mp4

    Triggered recordings contain event markers in the filename:
        - _alert_event_id_{id}
        - _analytics_disabled_{service}_timestamp_{ts}
        - _{event_type}_id_{id}

    Args:
        blob_name: Full blob path

    Returns:
        Tuple of (recording_type, specific_event_type)
        - recording_type: "continuous" or "triggered"
        - specific_event_type: For triggered, the specific type (alert, analytics_disabled, etc.)
    """
    filename = blob_name.split("/")[-1]

    # Check if the blob is in a triggered camera folder
    if "-triggered/" in blob_name:
        # Check for specific event types in the filename
        if "_alert_event_id_" in filename:
            return ("triggered", "alert")
        if "_analytics_disabled_" in filename:
            match = re.search(r"_analytics_disabled_(\w+)_timestamp_", filename)
            if match:
                return ("triggered", f"analytics_disabled_{match.group(1)}")
            return ("triggered", "analytics_disabled")
        match = re.search(r"_(\w+)_id_\d+", filename)
        if match:
            event_type = match.group(1)
            if event_type not in ("segment",):
                return ("triggered", event_type)
        # In a triggered folder but no specific event marker
        return ("triggered", "capture")

    # Check for alert events
    if "_alert_event_id_" in filename:
        return ("triggered", "alert")

    # Check for analytics disabled events
    if "_analytics_disabled_" in filename:
        match = re.search(r"_analytics_disabled_(\w+)_timestamp_", filename)
        if match:
            return ("triggered", f"analytics_disabled_{match.group(1)}")
        return ("triggered", "analytics_disabled")

    # Check for generic event ID pattern
    match = re.search(r"_(\w+)_id_\d+", filename)
    if match:
        event_type = match.group(1)
        if event_type not in ("segment",):  # Exclude false positives
            return ("triggered", event_type)

    # Default: continuous recording (standard segment format)
    return ("continuous", None)


def filter_segments_by_event_type(segments: list[dict], event_type_filter: str | None) -> list[dict]:
    """
    Filter segments by event type.

    Args:
        segments: List of segment metadata dictionaries
        event_type_filter: One of:
            - None: No filtering, return all
            - "continuous": Only continuous recordings
            - "triggered": Only triggered recordings (any type)
            - "<specific>": Only specific triggered type (alert, analytics_disabled, etc.)

    Returns:
        Filtered list of segments
    """
    if not event_type_filter:
        return segments

    event_type_filter = event_type_filter.lower().strip()
    filtered = []

    for segment in segments:
        recording_type, specific_type = detect_recording_type(segment["name"])

        if event_type_filter == "continuous":
            if recording_type == "continuous":
                filtered.append(segment)
        elif event_type_filter == "triggered":
            if recording_type == "triggered":
                filtered.append(segment)
        else:
            # Filter by specific event type
            if specific_type and specific_type.lower() == event_type_filter:
                filtered.append(segment)
            elif specific_type and event_type_filter in specific_type.lower():
                filtered.append(segment)

    return filtered


def segment_lookback_seconds() -> int:
    """How far before the query window discovery looks, from SEGMENT_LOOKBACK_SECONDS."""
    return _positive_int_env("SEGMENT_LOOKBACK_SECONDS", DEFAULT_SEGMENT_LOOKBACK_SECONDS)


def query_blobs_by_prefix(
    container: ContainerClient,
    camera_id: str,
    start_time: datetime,
    end_time: datetime,
    blob_prefix: str = "",
    lookback_seconds: int = 0,
) -> list[dict]:
    """
    List candidate recordings from the hourly prefixes covering a window.

    Candidates are video blobs whose filename time falls in
    `[start_time - lookback_seconds, end_time)`. Use select_overlapping_segments
    to keep only those whose footage overlaps the window. Listing failures
    raise DiscoveryError instead of returning partial results.

    Args:
        container: Blob container client
        camera_id: Camera identifier
        start_time: Query start time (naive UTC)
        end_time: Query end time (naive UTC)
        blob_prefix: Optional prefix for blob path (e.g., 'video-recordings')
        lookback_seconds: How far before start_time a recording may begin

    Returns:
        Candidate segments sorted by filename time
    """
    earliest = start_time - timedelta(seconds=lookback_seconds)
    segments = []

    hours_to_check = []
    current = earliest.replace(minute=0, second=0, microsecond=0)
    while current < end_time:
        hours_to_check.append(current)
        current += timedelta(hours=1)

    for hour in hours_to_check:
        prefix = f"{camera_id}/{hour.strftime('%Y/%m/%d/%H')}/"
        if blob_prefix:
            prefix = f"{blob_prefix}/{prefix}"
        logger.info(f"Querying prefix: {prefix}")

        try:
            for blob in container.list_blobs(name_starts_with=prefix):
                if not blob.name.lower().endswith(VIDEO_EXTENSIONS):
                    continue
                blob_time = parse_timestamp_from_blob_name(blob.name)
                if blob_time and earliest <= blob_time < end_time:
                    segments.append({"name": blob.name, "timestamp": blob_time, "size": blob.size})
        except AzureError as e:
            raise DiscoveryError(f"Listing failed for prefix {prefix}") from e

    segments.sort(key=lambda x: x["timestamp"])
    return segments


def select_overlapping_segments(
    container: ContainerClient, candidates: list[dict], start_time: datetime, end_time: datetime
) -> list[dict]:
    """
    Keep candidates whose footage overlaps `[start_time, end_time)`.

    The interval comes from the JSON sidecar when it holds a valid
    `segment_start` and `segment_end`, and a segment is kept when
    `segment_start < end_time and segment_end > start_time`. Without one, the
    filename time stands in for the footage and must fall inside the window;
    such segments are marked `timing: "filename"`.

    Returns:
        Selected segments with normalized `start`/`end` (aware UTC) and
        metadata fields, sorted by start
    """
    window_start = as_utc(start_time)
    window_end = as_utc(end_time)
    selected = []

    for segment, metadata in zip(candidates, fetch_metadata_for_segments(container, candidates), strict=True):
        enriched = segment.copy()
        footage_start = as_utc(metadata.get("segment_start")) if metadata else None
        footage_end = as_utc(metadata.get("segment_end")) if metadata else None

        if footage_start and footage_end and footage_end > footage_start:
            if not (footage_start < window_end and footage_end > window_start):
                continue
            enriched["timing"] = "metadata"
        else:
            footage_start = footage_end = as_utc(segment.get("timestamp"))
            if footage_start is None or not window_start <= footage_start < window_end:
                continue
            enriched["timing"] = "filename"

        enriched["start"] = footage_start
        enriched["end"] = footage_end
        if metadata:
            enriched["metadata"] = metadata
            enriched["segment_start"] = footage_start.isoformat() if enriched["timing"] == "metadata" else None
            enriched["segment_end"] = footage_end.isoformat() if enriched["timing"] == "metadata" else None
            enriched["duration_seconds"] = metadata.get("duration_seconds")
            enriched["location"] = metadata.get("location")
        selected.append(enriched)

    return sort_segments_by_metadata(selected)


def sort_segments_by_metadata(segments: list[dict]) -> list[dict]:
    """
    Sort segments by footage start.

    Uses the normalized `start`, then the sidecar `segment_start`, then the
    filename time, all compared as aware UTC. Segments without any valid time
    sort first.
    """

    def sort_key(seg):
        for value in (seg.get("start"), seg.get("segment_start"), seg.get("timestamp")):
            normalized = as_utc(value)
            if normalized is not None:
                return normalized
        return datetime.min.replace(tzinfo=UTC)

    return sorted(segments, key=sort_key)


def detect_segment_gaps(segments: list[dict], threshold_seconds: float = 5.0) -> list[dict]:
    """
    Detect gaps between consecutive segments using sidecar footage intervals.

    Args:
        segments: Sorted list of selected segments
        threshold_seconds: Minimum gap duration to report (default 5s)

    Returns:
        List of gap records with start, end, and duration
    """
    gaps = []
    for current, next_seg in zip(segments, segments[1:], strict=False):
        current_end = as_utc(current.get("segment_end"))
        next_start = as_utc(next_seg.get("segment_start"))
        if current_end is None or next_start is None:
            continue

        gap_seconds = (next_start - current_end).total_seconds()
        if gap_seconds > threshold_seconds:
            gaps.append(
                {
                    "after_segment": current["name"],
                    "before_segment": next_seg["name"],
                    "gap_start": current_end.isoformat(),
                    "gap_end": next_start.isoformat(),
                    "gap_seconds": round(gap_seconds, 2),
                }
            )

    return gaps


def calculate_stitch_metrics(segments: list[dict]) -> dict:
    """
    Calculate stitching metrics from segment metadata.

    Args:
        segments: List of selected segments

    Returns:
        Dictionary with total_duration, earliest_start, latest_end, locations
    """
    total_duration = 0.0
    earliest_start = None
    latest_end = None
    locations = set()

    for seg in segments:
        duration = seg.get("duration_seconds")
        if isinstance(duration, int | float):
            total_duration += duration

        start = as_utc(seg.get("segment_start"))
        if start is not None and (earliest_start is None or start < earliest_start):
            earliest_start = start

        end = as_utc(seg.get("segment_end"))
        if end is not None and (latest_end is None or end > latest_end):
            latest_end = end

        if seg.get("location"):
            locations.add(seg["location"])

    return {
        "total_duration_seconds": round(total_duration, 2) if total_duration > 0 else None,
        "earliest_segment_start": earliest_start.isoformat() if earliest_start else None,
        "latest_segment_end": latest_end.isoformat() if latest_end else None,
        "locations": sorted(locations) if locations else None,
        "metadata_coverage": sum(1 for s in segments if s.get("metadata")) / len(segments) if segments else 0,
    }


def download_segments(
    container: ContainerClient, segments: list[dict], temp_dir: Path, deadline: float | None = None
) -> list[Path]:
    """
    Download blob segments to temporary directory.

    Args:
        container: Blob container client
        segments: List of segment metadata
        temp_dir: Temporary directory path
        deadline: time.monotonic() value after which no further segment starts

    Returns:
        List of downloaded file paths
    """
    downloaded_files = []

    for i, segment in enumerate(segments):
        if deadline is not None and time.monotonic() >= deadline:
            raise StitchDeadlineError("Deadline reached while downloading segments")
        blob_name = segment["name"]
        local_path = temp_dir / f"segment_{i:03d}{Path(blob_name).suffix.lower() or '.mp4'}"

        logger.info(f"Downloading segment {i + 1}/{len(segments)}: {blob_name}")

        try:
            blob_client = container.get_blob_client(blob_name)
            with open(local_path, "wb") as f:
                blob_client.download_blob().readinto(f)

            downloaded_files.append(local_path)
        except Exception as e:
            logger.error(f"Failed to download segment {blob_name}: {e}")
            raise

    return downloaded_files


def concat_segments(input_files: list[Path], output_file: Path, timeout: float = 300) -> None:
    """
    Concatenate video segments using FFmpeg concat demuxer with copy codec.

    CRITICAL: All segments MUST have identical codec parameters.
    Use consistent encoding during capture with keyframe alignment.

    Performance: ~500ms for 30-minute video (no re-encoding)

    Args:
        input_files: List of input video file paths
        output_file: Output merged video file path
        timeout: Seconds FFmpeg may run

    Raises:
        subprocess.CalledProcessError: If FFmpeg fails
        subprocess.TimeoutExpired: If FFmpeg runs past the timeout
    """
    concat_file = output_file.parent / "concat.txt"

    with open(concat_file, "w") as f:
        for file_path in input_files:
            f.write(f"file '{file_path.absolute()}'\n")

    # Use bundled ffmpeg binary if available, otherwise fall back to system ffmpeg
    script_dir = Path(__file__).parent
    bundled_ffmpeg = script_dir / "bin" / "ffmpeg"
    if bundled_ffmpeg.exists():
        ffmpeg_path = str(bundled_ffmpeg)
    else:
        ffmpeg_path = os.getenv("FFMPEG_PATH", "ffmpeg")

    cmd = [ffmpeg_path, "-f", "concat", "-safe", "0", "-i", str(concat_file), "-c", "copy", "-y", str(output_file)]

    logger.info(f"Running FFmpeg: {' '.join(cmd)}")

    try:
        result = subprocess.run(  # noqa: S603
            cmd, check=True, capture_output=True, text=True, timeout=timeout
        )
        logger.info("FFmpeg completed successfully")
        if result.stderr:
            logger.debug(f"FFmpeg stderr: {result.stderr}")
    except subprocess.CalledProcessError as e:
        logger.error(f"FFmpeg failed with exit code {e.returncode}")
        logger.error(f"FFmpeg stderr: {e.stderr}")
        raise
    except subprocess.TimeoutExpired:
        logger.error(f"FFmpeg timed out after {timeout:.0f} seconds")
        raise


def get_user_delegation_key(blob_service_client: BlobServiceClient, expiry_hours: int) -> UserDelegationKey:
    """Request one user delegation key that can sign SAS tokens for the whole request."""
    return blob_service_client.get_user_delegation_key(
        key_start_time=datetime.now(UTC) - timedelta(minutes=5),
        key_expiry_time=datetime.now(UTC) + timedelta(hours=expiry_hours + 1),
    )


def generate_sas_url(
    blob_service_client: BlobServiceClient,
    container_name: str,
    blob_name: str,
    expiry_hours: int = 24,
    account_key: str | None = None,
    user_delegation_key: UserDelegationKey | None = None,
) -> str:
    """
    Generate SAS URL for blob with read-only permissions.

    Args:
        blob_service_client: Blob service client
        container_name: Container name
        blob_name: Blob name
        expiry_hours: SAS token expiry in hours
        account_key: Storage account key (optional, uses user delegation if None)
        user_delegation_key: Key reused across a request; requested here when omitted

    Returns:
        SAS URL for blob access
    """
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

    account_name = blob_service_client.account_name

    if account_key:
        # Use account key for SAS generation
        sas_token = generate_blob_sas(
            account_name=account_name,
            container_name=container_name,
            blob_name=blob_name,
            account_key=account_key,
            permission=BlobSasPermissions(read=True),
            start=datetime.now(UTC) - timedelta(minutes=5),
            expiry=datetime.now(UTC) + timedelta(hours=expiry_hours),
        )
    else:
        # Use user delegation key (requires managed identity)
        if user_delegation_key is None:
            user_delegation_key = get_user_delegation_key(blob_service_client, expiry_hours)
        sas_token = generate_blob_sas(
            account_name=account_name,
            container_name=container_name,
            blob_name=blob_name,
            user_delegation_key=user_delegation_key,
            permission=BlobSasPermissions(read=True),
            start=datetime.now(UTC) - timedelta(minutes=5),
            expiry=datetime.now(UTC) + timedelta(hours=expiry_hours),
        )

    sas_url = f"{blob_client.url}?{sas_token}"
    return sas_url


def parse_query_time(value: str) -> datetime:
    """Parse an ISO 8601 timestamp to naive UTC.

    Offset-aware input, including a trailing Z, is converted to UTC; input
    without an offset is treated as UTC.
    """
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(UTC).replace(tzinfo=None)
    return parsed


def stitch_max_seconds() -> int:
    """Longest window that stitch=true accepts, from STITCH_MAX_DURATION_SECONDS."""
    return _positive_int_env("STITCH_MAX_DURATION_SECONDS", DEFAULT_STITCH_MAX_SECONDS)


def _json_response(body: dict, status_code: int, headers: dict | None = None) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(body), status_code=status_code, mimetype="application/json", headers=headers)


def check_stitch_budget(segments: list[dict], staging_dir: str) -> func.HttpResponse | None:
    """Reject a stitch job that exceeds its segment, byte, or disk budget.

    Runs before anything is downloaded. Inputs and the merged output coexist
    on disk, so staging needs about twice the input size.
    """
    max_segments = _positive_int_env("STITCH_MAX_SEGMENTS", DEFAULT_STITCH_MAX_SEGMENTS)
    if len(segments) > max_segments:
        return _json_response(
            {"error": "Too many segments to stitch", "segment_count": len(segments), "max_segments": max_segments}, 400
        )

    total_bytes = sum(segment.get("size") or 0 for segment in segments)
    max_bytes = _positive_int_env("STITCH_MAX_BYTES", DEFAULT_STITCH_MAX_BYTES)
    if total_bytes > max_bytes:
        return _json_response(
            {"error": "Too much video to stitch", "total_bytes": total_bytes, "max_bytes": max_bytes}, 400
        )

    if shutil.disk_usage(staging_dir).free < 2 * total_bytes + STITCH_DISK_HEADROOM_BYTES:
        logger.warning(f"Not enough temporary storage to stitch {total_bytes} bytes")
        return _json_response(
            {"error": "Not enough temporary storage to stitch", "retry_after_seconds": STITCH_RETRY_AFTER_SECONDS},
            503,
            {"Retry-After": str(STITCH_RETRY_AFTER_SECONDS)},
        )
    return None


def stitch_segments(
    blob_service_client: BlobServiceClient,
    video_container: ContainerClient,
    segments: list[dict],
    camera_id: str,
    start_time: datetime,
    end_time: datetime,
    deadline: float,
) -> str:
    """Download, concatenate, and upload segments; return the stitched blob name.

    Each result gets a unique, create-only blob name, so a SAS URL that's
    already been shared always returns the footage it was issued for.
    """
    temp_container_name = os.getenv("TEMP_VIDEOS_CONTAINER", "temp-videos")
    temp_dir = Path(tempfile.mkdtemp(prefix="video_query_"))
    try:
        downloaded_files = download_segments(video_container, segments, temp_dir, deadline)

        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise StitchDeadlineError("Deadline reached before concatenation")
        output_file = temp_dir / "merged.mp4"
        concat_segments(downloaded_files, output_file, timeout=remaining)

        if time.monotonic() >= deadline:
            raise StitchDeadlineError("Deadline reached before upload")
        merged_blob_name = (
            f"temp/{camera_id}/{start_time.strftime('%Y%m%dT%H%M%S')}_{end_time.strftime('%Y%m%dT%H%M%S')}"
            f"_{uuid.uuid4().hex}.mp4"
        )
        temp_container = blob_service_client.get_container_client(temp_container_name)
        logger.info(f"Uploading merged video to {merged_blob_name}")
        with open(output_file, "rb") as data:
            temp_container.upload_blob(name=merged_blob_name, data=data, overwrite=False)
        return merged_blob_name
    finally:
        try:
            shutil.rmtree(temp_dir)
        except OSError as e:
            logger.warning(f"Failed to clean up temporary directory {temp_dir}: {e}")


@app.route(route="video", methods=["GET"], auth_level=func.AuthLevel.FUNCTION)
def get_video(req: func.HttpRequest) -> func.HttpResponse:
    """
    Query and retrieve video for specific camera and timeframe.

    Returns recordings whose footage overlaps the window. Recordings are
    returned whole; stitched output isn't trimmed to the window, and the
    response reports the actual footage range.

    Query Parameters:
        camera: Camera ID (required)
        start: Start timestamp in ISO 8601 format (required)
        end: End timestamp in ISO 8601 format (required)
        event_type: Filter by recording type (optional)
            - "continuous": Only continuous recordings
            - "triggered": Only MQTT-triggered recordings
            - "<specific>": Specific event type (alert, analytics_disabled, etc.)
        stitch: Whether to stitch segments server-side (optional, default: false)

    Returns:
        JSON response with segment URLs or a stitched video_url
    """
    request_started = time.monotonic()
    logger.info("Video query request received")

    try:
        camera_id = req.params.get("camera")
        start_str = req.params.get("start")
        end_str = req.params.get("end")
        stitch = req.params.get("stitch", "false").lower() == "true"
        event_type_filter = req.params.get("event_type")

        if not camera_id:
            return _json_response({"error": "Missing required parameter: camera"}, 400)

        if not CAMERA_ID_PATTERN.fullmatch(camera_id):
            return _json_response({"error": "Invalid camera_id format"}, 400)

        if not start_str or not end_str:
            return _json_response({"error": "Missing required parameters: start and end"}, 400)

        try:
            start_time = parse_query_time(start_str)
            end_time = parse_query_time(end_str)
        except ValueError:
            return _json_response({"error": "Invalid timestamp format; use ISO 8601"}, 400)

        if end_time <= start_time:
            return _json_response({"error": "end time must be after start time"}, 400)

        duration_seconds = (end_time - start_time).total_seconds()

        if duration_seconds > 86400:
            return _json_response({"error": "Maximum query duration is 24 hours"}, 400)

        if stitch and duration_seconds > stitch_max_seconds():
            return _json_response(
                {"error": "Stitched query window too long", "max_stitch_duration_seconds": stitch_max_seconds()}, 400
            )

        try:
            blob_service_client, account_key = _storage_client()
        except StorageConfigError:
            logger.exception("Storage connection not configured")
            return _json_response({"error": "Storage connection not configured"}, 500)

        video_container_name = os.getenv("VIDEO_RECORDINGS_CONTAINER", "video-recordings")
        sas_expiry_hours = int(os.getenv("SAS_EXPIRY_HOURS", "24"))
        video_container = blob_service_client.get_container_client(video_container_name)

        # Optional blob prefix for subvolume path (e.g., 'video-recordings')
        blob_prefix = os.getenv("VIDEO_BLOB_PREFIX", "")

        try:
            candidates = query_blobs_by_prefix(
                video_container, camera_id, start_time, end_time, blob_prefix, segment_lookback_seconds()
            )
            if event_type_filter:
                candidates = filter_segments_by_event_type(candidates, event_type_filter)
            segments = select_overlapping_segments(video_container, candidates, start_time, end_time)
        except DiscoveryError:
            logger.exception("Recording discovery failed")
            return _json_response({"error": "Recording discovery failed"}, 502)

        base_response = {
            "camera_id": camera_id,
            "start_time": start_str,
            "end_time": end_str,
            "event_type_filter": event_type_filter,
        }

        if not segments:
            # Return 200 with empty results - 404 should only be for missing resources
            return _json_response(
                {
                    "segments": [],
                    "total_segments": 0,
                    **base_response,
                    "message": "No video segments found for requested timeframe",
                },
                200,
            )

        logger.info(f"Found {len(segments)} segments for camera {camera_id}")

        if stitch:
            recording_types = sorted({detect_recording_type(s["name"])[0] for s in segments})
            if len(recording_types) > 1:
                return _json_response(
                    {
                        "error": "Stitching needs a single recording type; set event_type",
                        "recording_types": recording_types,
                    },
                    400,
                )

            rejection = check_stitch_budget(segments, tempfile.gettempdir())
            if rejection is not None:
                return rejection

            if not _stitch_slots.acquire(blocking=False):
                return _json_response(
                    {"error": "Stitching is busy; retry later", "retry_after_seconds": STITCH_RETRY_AFTER_SECONDS},
                    429,
                    {"Retry-After": str(STITCH_RETRY_AFTER_SECONDS)},
                )
            deadline_seconds = _positive_int_env("STITCH_DEADLINE_SECONDS", DEFAULT_STITCH_DEADLINE_SECONDS)
            try:
                user_delegation_key = (
                    None if account_key else get_user_delegation_key(blob_service_client, sas_expiry_hours)
                )
                gaps = detect_segment_gaps(segments)
                stitch_metrics = calculate_stitch_metrics(segments)
                merged_blob_name = stitch_segments(
                    blob_service_client,
                    video_container,
                    segments,
                    camera_id,
                    start_time,
                    end_time,
                    request_started + deadline_seconds,
                )
            except (StitchDeadlineError, subprocess.TimeoutExpired):
                logger.exception("Stitching exceeded the request deadline")
                return _json_response(
                    {
                        "error": "Stitching didn't finish within the request deadline",
                        "deadline_seconds": deadline_seconds,
                    },
                    504,
                )
            except AzureError:
                logger.exception("Recording retrieval for stitching failed")
                return _json_response({"error": "Recording retrieval failed"}, 502)
            finally:
                _stitch_slots.release()

            sas_url = generate_sas_url(
                blob_service_client,
                os.getenv("TEMP_VIDEOS_CONTAINER", "temp-videos"),
                merged_blob_name,
                sas_expiry_hours,
                account_key,
                user_delegation_key,
            )

            response_data = {
                "video_url": sas_url,
                "query_duration_seconds": duration_seconds,
                "segment_count": len(segments),
                **base_response,
                "expires_at": (datetime.now(UTC) + timedelta(hours=sas_expiry_hours)).isoformat(),
                "stitched": True,
                "trimmed": False,
            }
            if stitch_metrics.get("total_duration_seconds"):
                response_data["actual_duration_seconds"] = stitch_metrics["total_duration_seconds"]
            if stitch_metrics.get("earliest_segment_start"):
                response_data["earliest_segment_start"] = stitch_metrics["earliest_segment_start"]
            if stitch_metrics.get("latest_segment_end"):
                response_data["latest_segment_end"] = stitch_metrics["latest_segment_end"]
            if stitch_metrics.get("locations"):
                response_data["locations"] = stitch_metrics["locations"]
            response_data["metadata_coverage"] = round(stitch_metrics.get("metadata_coverage", 0) * 100, 1)
            if gaps:
                response_data["gaps"] = gaps
                response_data["gap_count"] = len(gaps)
                response_data["total_gap_seconds"] = round(sum(g["gap_seconds"] for g in gaps), 2)

            logger.info(f"Video query completed successfully for camera {camera_id}")
            return _json_response(response_data, 200)

        # One user delegation key signs every SAS URL in this response
        user_delegation_key = None if account_key else get_user_delegation_key(blob_service_client, sas_expiry_hours)
        segment_urls = []
        for segment in segments:
            recording_type, specific_event = detect_recording_type(segment["name"])
            segment_data = {
                "url": generate_sas_url(
                    blob_service_client,
                    video_container_name,
                    segment["name"],
                    sas_expiry_hours,
                    account_key,
                    user_delegation_key,
                ),
                "name": segment["name"],
                "timestamp": segment["timestamp"].isoformat() if segment.get("timestamp") else None,
                "size_bytes": segment.get("size"),
                "recording_type": recording_type,
                "event_type": specific_event,
                "timing": segment["timing"],
            }
            if segment.get("metadata"):
                segment_data["duration_seconds"] = segment.get("duration_seconds")
                segment_data["location"] = segment.get("location")
                segment_data["segment_start"] = segment.get("segment_start")
                segment_data["segment_end"] = segment.get("segment_end")
            segment_urls.append(segment_data)

        logger.info(f"Video query completed successfully for camera {camera_id}")
        return _json_response(
            {
                "segments": segment_urls,
                "total_segments": len(segments),
                **base_response,
                "expires_at": (datetime.now(UTC) + timedelta(hours=sas_expiry_hours)).isoformat(),
                "stitched": False,
            },
            200,
        )

    except Exception:
        logger.exception("Unexpected error processing video query")
        return _json_response({"error": "Internal server error"}, 500)


@app.route(route="trigger", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def trigger_capture(req: func.HttpRequest) -> func.HttpResponse:
    """Trigger a video capture event via Event Grid MQTT."""
    allowed_cameras = _allowed_trigger_cameras()
    if not allowed_cameras:
        return func.HttpResponse(
            json.dumps({"error": "Trigger not configured"}),
            status_code=503,
            mimetype="application/json",
        )

    camera = req.params.get("camera", "")
    if camera not in allowed_cameras:
        return func.HttpResponse(
            json.dumps({"error": "Invalid camera"}),
            status_code=400,
            mimetype="application/json",
        )

    now = time.time()
    last_trigger = _trigger_rate_limits.get(camera, 0)
    if now - last_trigger < TRIGGER_RATE_LIMIT_SECONDS:
        remaining = int(TRIGGER_RATE_LIMIT_SECONDS - (now - last_trigger))
        return func.HttpResponse(
            json.dumps({"error": "Rate limited", "retry_after_seconds": remaining, "camera": camera}),
            status_code=429,
            mimetype="application/json",
        )

    timestamp_ms = int(now * 1000)
    event_id = int(now) % 1000000
    trigger_payload = json.dumps(
        {
            "Alert": True,
            "attributes": {
                "devices": [
                    {
                        "device_data": {
                            "type": "ALERT_DLQC",
                            "timestamp": timestamp_ms,
                            "event_id": event_id,
                            "camera_id": camera,
                        }
                    }
                ]
            },
        }
    )

    eg_hostname = os.environ.get("EVENT_GRID_HOSTNAME", "")
    if not eg_hostname:
        return func.HttpResponse(
            json.dumps({"error": "Event Grid not configured", "detail": "EVENT_GRID_HOSTNAME not set"}),
            status_code=503,
            mimetype="application/json",
        )

    try:
        _publish_mqtt_trigger(
            hostname=eg_hostname,
            topic=f"{TRIGGER_TOPIC_PREFIX}/{camera}",
            payload=trigger_payload,
        )
    except Exception:
        logging.exception("MQTT trigger publish failed")
        return func.HttpResponse(
            json.dumps({"error": "Trigger delivery failed"}),
            status_code=502,
            mimetype="application/json",
        )

    _trigger_rate_limits[camera] = now

    return func.HttpResponse(
        json.dumps(
            {
                "status": "accepted",
                "camera": camera,
                "event_id": event_id,
                "timestamp": timestamp_ms,
                "estimated_ready_seconds": 120,
                "message": f"Trigger sent for {camera}. Video should be queryable in ~2 minutes.",
            }
        ),
        status_code=202,
        mimetype="application/json",
    )
