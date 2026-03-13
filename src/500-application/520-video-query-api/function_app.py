"""
Video Query API - Azure Function for time-based video queries.

Provides REST endpoint for querying and retrieving video segments from
continuous camera recordings stored in Azure Blob Storage.

Supports filtering by event_type:
- continuous: Regular continuous recording segments
- triggered: MQTT-triggered capture segments (alerts, analytics events)
- <specific>: Filter by specific event type (alert, analytics_disabled, etc.)
"""

import os
import json
import logging
import re
import ssl
import tempfile
import time
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List, Dict, Optional, Literal
import hashlib

import azure.functions as func
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import (
    BlobServiceClient,
    ContainerClient,
    generate_blob_sas,
    BlobSasPermissions
)
import paho.mqtt.client as mqtt

app = func.FunctionApp()

# Configure logging
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)

# Trigger endpoint configuration
_trigger_rate_limits: dict[str, float] = {}
TRIGGER_RATE_LIMIT_SECONDS = 30
ALLOWED_CAMERAS = {
    "pmn-camera-01-triggered",
    "pmn-camera-02-triggered",
    "pmn-camera-03-triggered",
    "pmn-camera-04-triggered",
}
EVENT_GRID_MQTT_SCOPE = "https://eventgrid.azure.net/.default"


def _publish_mqtt_trigger(hostname: str, topic: str, payload: str) -> None:
    """Publish a message to Event Grid namespace via MQTT with managed identity auth."""
    credential = ManagedIdentityCredential()
    token = credential.get_token(EVENT_GRID_MQTT_SCOPE).token
    client_id = os.environ.get("AZURE_CLIENT_ID", "video-query-trigger")

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=client_id,
        protocol=mqtt.MQTTv5,
    )
    client.username_pw_set(username=client_id, password=token)
    client.tls_set(tls_version=ssl.PROTOCOL_TLS_CLIENT)

    client.connect(hostname, port=8883)
    client.loop_start()
    try:
        result = client.publish(topic, payload, qos=1)
        result.wait_for_publish(timeout=10)
    finally:
        client.loop_stop()
        client.disconnect()


@app.route(route="health", auth_level=func.AuthLevel.ANONYMOUS)
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint that tests blob storage connectivity."""
    storage_account_name = os.getenv("STORAGE_ACCOUNT_NAME")
    container_name = os.getenv(
        "VIDEO_RECORDINGS_CONTAINER", "video-recordings")
    blob_prefix = os.getenv("VIDEO_BLOB_PREFIX", "")
    connection_string = os.getenv("STORAGE_CONNECTION_STRING")

    try:
        if connection_string:
            # Use connection string if available
            blob_service_client = BlobServiceClient.from_connection_string(
                connection_string)
        else:
            # Fall back to managed identity
            credential = ManagedIdentityCredential()
            account_url = f"https://{storage_account_name}.blob.core.windows.net"
            blob_service_client = BlobServiceClient(
                account_url=account_url,
                credential=credential
            )
        container = blob_service_client.get_container_client(container_name)

        # Try to list a few blobs
        blob_count = 0
        blob_names = []
        for blob in container.list_blobs(name_starts_with=blob_prefix, results_per_page=5):
            blob_count += 1
            blob_names.append(blob.name)
            if blob_count >= 5:
                break

        return func.HttpResponse(
            json.dumps({
                "status": "healthy",
                "storage_account": storage_account_name,
                "container": container_name,
                "blob_prefix": blob_prefix,
                "blobs_found": blob_count,
                "sample_blobs": blob_names,
                "auth_method": "connection_string" if connection_string else "managed_identity"
            }),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        return func.HttpResponse(
            json.dumps({
                "status": "unhealthy",
                "error": str(e),
                "storage_account": storage_account_name,
                "container": container_name
            }),
            status_code=500,
            mimetype="application/json"
        )


def calculate_hash_prefix(camera_id: str) -> str:
    """
    Calculate hash prefix for camera ID matching Phase 1 implementation.

    Args:
        camera_id: Camera identifier

    Returns:
        Three-digit hash prefix (000-999)
    """
    hash_digest = hashlib.md5(camera_id.encode()).digest()
    prefix = hash_digest[0] % 1000
    return f"{prefix:03d}"


def parse_timestamp_from_blob_name(blob_name: str) -> Optional[datetime]:
    """
    Parse timestamp from blob name for both continuous and triggered recordings.

    Supported formats:
        Continuous: {camera}/{YYYY}/{MM}/{DD}/{HH}/segment_{timestamp}_{camera}.mp4
            Example: segment_2026-01-30T19:05:44Z_pmn-camera-01.mp4

        Triggered: {camera}/{YYYY}/{MM}/{DD}/{HH}/{timestamp}_{event_type}_id_{id}.mkv
            Example: 2026-01-30_190544_alert_event_id_12345.mkv

    Args:
        blob_name: Blob path

    Returns:
        Datetime object (timezone-naive UTC) or None if parsing fails
    """
    try:
        parts = blob_name.split('/')
        if len(parts) < 6:
            return None

        filename = parts[-1]

        # Try continuous format: segment_{ISO8601_timestamp}_{camera}.mp4
        if filename.startswith("segment_"):
            timestamp_str = filename.split('_')[1]
            if timestamp_str.endswith('Z'):
                timestamp_str = timestamp_str[:-1]
            dt = datetime.fromisoformat(timestamp_str)
            if dt.tzinfo is not None:
                dt = dt.replace(tzinfo=None)
            return dt

        # Try triggered format: {YYYY-MM-DD}_{HHMMSS}_...
        # Example: 2026-01-30_190544_alert_event_id_12345.mkv
        match = re.match(r'^(\d{4}-\d{2}-\d{2})_(\d{6})_', filename)
        if match:
            date_str = match.group(1)
            time_str = match.group(2)
            timestamp_str = f"{date_str}T{time_str[:2]}:{time_str[2:4]}:{time_str[4:6]}"
            return datetime.fromisoformat(timestamp_str)

        # Fallback: try to extract timestamp from path hierarchy
        # Path format: {camera}/{YYYY}/{MM}/{DD}/{HH}/...
        if len(parts) >= 5:
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
        logger.warning(
            f"Failed to parse timestamp from blob name {blob_name}: {e}")
        return None


# Event type detection patterns for triggered recordings
TRIGGERED_PATTERNS = [
    re.compile(r'_alert_event_id_\d+'),
    re.compile(r'_analytics_disabled_\w*_timestamp_\d+'),
    re.compile(r'_\w+_id_\d+'),
]


def fetch_segment_metadata(
    container: ContainerClient,
    video_blob_name: str
) -> Optional[Dict]:
    """
    Fetch companion JSON metadata for a video segment.

    Args:
        container: Blob container client
        video_blob_name: Path to the video blob (e.g., "camera/2026/02/04/18/segment_xxx.mp4")

    Returns:
        Dictionary with metadata fields or None if not found
    """
    # Derive JSON metadata path from video path
    json_blob_name = video_blob_name.rsplit('.', 1)[0] + '.json'

    try:
        blob_client = container.get_blob_client(json_blob_name)
        blob_data = blob_client.download_blob()
        metadata = json.loads(blob_data.readall().decode('utf-8'))
        logger.debug(f"Fetched metadata for {video_blob_name}: {metadata}")
        return metadata
    except Exception as e:
        logger.debug(f"No metadata found for {video_blob_name}: {e}")
        return None


def detect_recording_type(blob_name: str) -> tuple[Literal["continuous", "triggered"], Optional[str]]:
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
    filename = blob_name.split('/')[-1]

    # Check if the blob is in a triggered camera folder
    if '-triggered/' in blob_name:
        # Check for specific event types in the filename
        if '_alert_event_id_' in filename:
            return ("triggered", "alert")
        if '_analytics_disabled_' in filename:
            match = re.search(r'_analytics_disabled_(\w+)_timestamp_', filename)
            if match:
                return ("triggered", f"analytics_disabled_{match.group(1)}")
            return ("triggered", "analytics_disabled")
        match = re.search(r'_(\w+)_id_\d+', filename)
        if match:
            event_type = match.group(1)
            if event_type not in ('segment',):
                return ("triggered", event_type)
        # In a triggered folder but no specific event marker
        return ("triggered", "capture")

    # Check for alert events
    if '_alert_event_id_' in filename:
        return ("triggered", "alert")

    # Check for analytics disabled events
    if '_analytics_disabled_' in filename:
        match = re.search(r'_analytics_disabled_(\w+)_timestamp_', filename)
        if match:
            return ("triggered", f"analytics_disabled_{match.group(1)}")
        return ("triggered", "analytics_disabled")

    # Check for generic event ID pattern
    match = re.search(r'_(\w+)_id_\d+', filename)
    if match:
        event_type = match.group(1)
        if event_type not in ('segment',):  # Exclude false positives
            return ("triggered", event_type)

    # Default: continuous recording (standard segment format)
    return ("continuous", None)


def filter_segments_by_event_type(
    segments: List[Dict],
    event_type_filter: Optional[str]
) -> List[Dict]:
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
        recording_type, specific_type = detect_recording_type(segment['name'])

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


def query_blobs_by_prefix(
    container: ContainerClient,
    camera_id: str,
    start_time: datetime,
    end_time: datetime,
    blob_prefix: str = ""
) -> List[Dict]:
    """
    Query blobs using prefix-based list (optimized for < 1 hour queries).

    Args:
        container: Blob container client
        camera_id: Camera identifier
        start_time: Query start time
        end_time: Query end time
        blob_prefix: Optional prefix for blob path (e.g., 'video-recordings')

    Returns:
        List of blob metadata dictionaries
    """
    segments = []

    hours_to_check = set()
    current = start_time.replace(minute=0, second=0, microsecond=0)
    while current <= end_time:
        hours_to_check.add(current)
        current += timedelta(hours=1)

    for hour in hours_to_check:
        if blob_prefix:
            prefix = f"{blob_prefix}/{camera_id}/{hour.strftime('%Y/%m/%d/%H')}"
        else:
            prefix = f"{camera_id}/{hour.strftime('%Y/%m/%d/%H')}"
        logger.info(f"Querying prefix: {prefix}")

        try:
            blob_count = 0
            video_extensions = ('.mp4', '.mkv', '.avi', '.mov')
            for blob in container.list_blobs(name_starts_with=prefix):
                blob_count += 1
                if not blob.name.lower().endswith(video_extensions):
                    logger.debug(f"Skipping non-video blob: {blob.name}")
                    continue
                logger.info(f"Found blob: {blob.name}")
                blob_time = parse_timestamp_from_blob_name(blob.name)
                logger.info(
                    f"Parsed timestamp: {blob_time}, start: {start_time}, end: {end_time}")
                if blob_time and start_time <= blob_time < end_time:
                    segments.append({
                        'name': blob.name,
                        'timestamp': blob_time,
                        'size': blob.size
                    })
            logger.info(f"Found {blob_count} blobs with prefix {prefix}")
        except Exception as e:
            logger.error(
                f"Error listing blobs with prefix {prefix}: {e}", exc_info=True)

    segments.sort(key=lambda x: x['timestamp'])
    return segments


def query_blobs_by_tags(
    container: ContainerClient,
    camera_id: str,
    start_time: datetime,
    end_time: datetime
) -> List[Dict]:
    """
    Query blobs using blob index tags (optimized for 1-24 hour queries).

    Args:
        container: Blob container client
        camera_id: Camera identifier
        start_time: Query start time
        end_time: Query end time

    Returns:
        List of blob metadata dictionaries
    """
    query = (
        f"camera_id='{camera_id}' AND "
        f"start_time>='{start_time.isoformat()}' AND "
        f"end_time<='{end_time.isoformat()}'"
    )

    logger.info(f"Querying blobs by tags: {query}")

    segments = []
    video_extensions = ('.mp4', '.mkv', '.avi', '.mov')
    try:
        for blob in container.find_blobs_by_tags(filter_expression=query):
            if not blob.name.lower().endswith(video_extensions):
                logger.debug(f"Skipping non-video blob: {blob.name}")
                continue
            blob_time = parse_timestamp_from_blob_name(blob.name)
            if blob_time:
                segments.append({
                    'name': blob.name,
                    'timestamp': blob_time,
                    'size': getattr(blob, 'size', 0)
                })
    except Exception as e:
        logger.error(f"Error querying blobs by tags: {e}")

    segments.sort(key=lambda x: x['timestamp'])
    return segments


def enrich_segments_with_metadata(
    container: ContainerClient,
    segments: List[Dict]
) -> List[Dict]:
    """
    Fetch and attach JSON metadata to each video segment.

    Args:
        container: Blob container client
        segments: List of segment metadata dictionaries

    Returns:
        Segments enriched with metadata fields (segment_start, segment_end, duration_seconds, location)
    """
    enriched = []
    for segment in segments:
        metadata = fetch_segment_metadata(container, segment['name'])
        enriched_segment = segment.copy()
        if metadata:
            enriched_segment['metadata'] = metadata
            enriched_segment['segment_start'] = metadata.get('segment_start')
            enriched_segment['segment_end'] = metadata.get('segment_end')
            enriched_segment['duration_seconds'] = metadata.get(
                'duration_seconds')
            enriched_segment['location'] = metadata.get('location')
        enriched.append(enriched_segment)
    return enriched


def sort_segments_by_metadata(segments: List[Dict]) -> List[Dict]:
    """
    Sort segments by precise segment_start timestamp from metadata.
    Falls back to filename-parsed timestamp if metadata unavailable.

    Args:
        segments: List of enriched segment dictionaries

    Returns:
        Segments sorted by segment_start (most precise) or timestamp (fallback)
    """
    def sort_key(seg):
        # Prefer segment_start from metadata for precise ordering
        if seg.get('segment_start'):
            try:
                return datetime.fromisoformat(seg['segment_start'].replace('Z', '+00:00'))
            except (ValueError, TypeError):
                pass
        # Fall back to filename-parsed timestamp (convert naive to UTC-aware for comparison)
        ts = seg.get('timestamp')
        if ts:
            if ts.tzinfo is None:
                return ts.replace(tzinfo=timezone.utc)
            return ts
        return datetime.min.replace(tzinfo=timezone.utc)

    return sorted(segments, key=sort_key)


def detect_segment_gaps(segments: List[Dict], threshold_seconds: float = 5.0) -> List[Dict]:
    """
    Detect gaps between consecutive segments using metadata timestamps.

    Args:
        segments: Sorted list of enriched segments
        threshold_seconds: Minimum gap duration to report (default 5s)

    Returns:
        List of gap records with start, end, and duration
    """
    gaps = []
    for i in range(len(segments) - 1):
        current = segments[i]
        next_seg = segments[i + 1]

        current_end = current.get('segment_end')
        next_start = next_seg.get('segment_start')

        if current_end and next_start:
            try:
                end_time = datetime.fromisoformat(
                    current_end.replace('Z', '+00:00'))
                start_time = datetime.fromisoformat(
                    next_start.replace('Z', '+00:00'))
                gap_seconds = (start_time - end_time).total_seconds()

                if gap_seconds > threshold_seconds:
                    gaps.append({
                        "after_segment": current['name'],
                        "before_segment": next_seg['name'],
                        "gap_start": current_end,
                        "gap_end": next_start,
                        "gap_seconds": round(gap_seconds, 2)
                    })
            except (ValueError, TypeError):
                pass

    return gaps


def calculate_stitch_metrics(segments: List[Dict]) -> Dict:
    """
    Calculate stitching metrics from segment metadata.

    Args:
        segments: List of enriched segments

    Returns:
        Dictionary with total_duration, earliest_start, latest_end, locations
    """
    total_duration = 0.0
    earliest_start = None
    latest_end = None
    locations = set()

    for seg in segments:
        # Sum actual durations from metadata
        if seg.get('duration_seconds'):
            total_duration += seg['duration_seconds']

        # Track time range
        if seg.get('segment_start'):
            try:
                start = datetime.fromisoformat(
                    seg['segment_start'].replace('Z', '+00:00'))
                if earliest_start is None or start < earliest_start:
                    earliest_start = start
            except (ValueError, TypeError):
                pass

        if seg.get('segment_end'):
            try:
                end = datetime.fromisoformat(
                    seg['segment_end'].replace('Z', '+00:00'))
                if latest_end is None or end > latest_end:
                    latest_end = end
            except (ValueError, TypeError):
                pass

        # Collect locations
        if seg.get('location'):
            locations.add(seg['location'])

    return {
        "total_duration_seconds": round(total_duration, 2) if total_duration > 0 else None,
        "earliest_segment_start": earliest_start.isoformat() if earliest_start else None,
        "latest_segment_end": latest_end.isoformat() if latest_end else None,
        "locations": list(locations) if locations else None,
        "metadata_coverage": sum(1 for s in segments if s.get('metadata')) / len(segments) if segments else 0
    }


def download_segments(
    container: ContainerClient,
    segments: List[Dict],
    temp_dir: Path
) -> List[Path]:
    """
    Download blob segments to temporary directory.

    Args:
        container: Blob container client
        segments: List of segment metadata
        temp_dir: Temporary directory path

    Returns:
        List of downloaded file paths
    """
    downloaded_files = []

    for i, segment in enumerate(segments):
        blob_name = segment['name']
        local_path = temp_dir / f"segment_{i:03d}.mp4"

        logger.info(f"Downloading segment {i+1}/{len(segments)}: {blob_name}")

        try:
            blob_client = container.get_blob_client(blob_name)
            with open(local_path, "wb") as f:
                blob_data = blob_client.download_blob()
                f.write(blob_data.readall())

            downloaded_files.append(local_path)
        except Exception as e:
            logger.error(f"Failed to download segment {blob_name}: {e}")
            raise

    return downloaded_files


def concat_segments(input_files: List[Path], output_file: Path) -> None:
    """
    Concatenate video segments using FFmpeg concat demuxer with copy codec.

    CRITICAL: All segments MUST have identical codec parameters.
    Use consistent encoding during capture with keyframe alignment.

    Performance: ~500ms for 30-minute video (no re-encoding)

    Args:
        input_files: List of input video file paths
        output_file: Output merged video file path

    Raises:
        subprocess.CalledProcessError: If FFmpeg fails
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

    cmd = [
        ffmpeg_path,
        "-f", "concat",
        "-safe", "0",
        "-i", str(concat_file),
        "-c", "copy",
        "-y",
        str(output_file)
    ]

    logger.info(f"Running FFmpeg: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            timeout=300
        )
        logger.info("FFmpeg completed successfully")
        if result.stderr:
            logger.debug(f"FFmpeg stderr: {result.stderr}")
    except subprocess.CalledProcessError as e:
        logger.error(f"FFmpeg failed with exit code {e.returncode}")
        logger.error(f"FFmpeg stderr: {e.stderr}")
        raise
    except subprocess.TimeoutExpired:
        logger.error("FFmpeg timed out after 300 seconds")
        raise


def generate_sas_url(
    blob_service_client: BlobServiceClient,
    container_name: str,
    blob_name: str,
    expiry_hours: int = 24,
    account_key: str = None
) -> str:
    """
    Generate SAS URL for blob with read-only permissions.

    Args:
        blob_service_client: Blob service client
        container_name: Container name
        blob_name: Blob name
        expiry_hours: SAS token expiry in hours
        account_key: Storage account key (optional, uses user delegation if None)

    Returns:
        SAS URL for blob access
    """
    blob_client = blob_service_client.get_blob_client(
        container=container_name,
        blob=blob_name
    )

    account_name = blob_service_client.account_name

    if account_key:
        # Use account key for SAS generation
        sas_token = generate_blob_sas(
            account_name=account_name,
            container_name=container_name,
            blob_name=blob_name,
            account_key=account_key,
            permission=BlobSasPermissions(read=True),
            start=datetime.utcnow() - timedelta(minutes=5),
            expiry=datetime.utcnow() + timedelta(hours=expiry_hours)
        )
    else:
        # Use user delegation key (requires managed identity)
        key_start_time = datetime.utcnow() - timedelta(minutes=5)
        key_expiry_time = datetime.utcnow() + timedelta(hours=expiry_hours + 1)
        user_delegation_key = blob_service_client.get_user_delegation_key(
            key_start_time=key_start_time,
            key_expiry_time=key_expiry_time
        )
        sas_token = generate_blob_sas(
            account_name=account_name,
            container_name=container_name,
            blob_name=blob_name,
            user_delegation_key=user_delegation_key,
            permission=BlobSasPermissions(read=True),
            start=datetime.utcnow() - timedelta(minutes=5),
            expiry=datetime.utcnow() + timedelta(hours=expiry_hours)
        )

    sas_url = f"{blob_client.url}?{sas_token}"
    return sas_url


@app.route(route="video", methods=["GET"], auth_level=func.AuthLevel.FUNCTION)
def get_video(req: func.HttpRequest) -> func.HttpResponse:
    """
    Query and retrieve video for specific camera and timeframe.

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
        JSON response with video_url, duration, segments count
    """
    logger.info("Video query request received")

    try:
        camera_id = req.params.get('camera')
        start_str = req.params.get('start')
        end_str = req.params.get('end')
        stitch = req.params.get('stitch', 'false').lower() == 'true'
        event_type_filter = req.params.get('event_type')

        if not camera_id:
            return func.HttpResponse(
                json.dumps({"error": "Missing required parameter: camera"}),
                status_code=400,
                mimetype="application/json"
            )

        if not start_str or not end_str:
            return func.HttpResponse(
                json.dumps(
                    {"error": "Missing required parameters: start and end"}),
                status_code=400,
                mimetype="application/json"
            )

        try:
            # Parse timestamps, handling Z suffix and ensuring timezone-naive UTC
            start_str_clean = start_str.replace('Z', '')
            end_str_clean = end_str.replace('Z', '')
            start_time = datetime.fromisoformat(start_str_clean)
            end_time = datetime.fromisoformat(end_str_clean)
            # Strip timezone info if present (assume UTC)
            if start_time.tzinfo is not None:
                start_time = start_time.replace(tzinfo=None)
            if end_time.tzinfo is not None:
                end_time = end_time.replace(tzinfo=None)
        except ValueError as e:
            return func.HttpResponse(
                json.dumps({"error": f"Invalid timestamp format: {e}"}),
                status_code=400,
                mimetype="application/json"
            )

        if end_time <= start_time:
            return func.HttpResponse(
                json.dumps({"error": "end time must be after start time"}),
                status_code=400,
                mimetype="application/json"
            )

        duration_seconds = (end_time - start_time).total_seconds()

        if duration_seconds > 86400:
            return func.HttpResponse(
                json.dumps({"error": "Maximum query duration is 24 hours"}),
                status_code=400,
                mimetype="application/json"
            )

        storage_account_name = os.getenv("STORAGE_ACCOUNT_NAME")
        if not storage_account_name:
            logger.error("STORAGE_ACCOUNT_NAME not configured")
            return func.HttpResponse(
                json.dumps({"error": "Storage connection not configured"}),
                status_code=500,
                mimetype="application/json"
            )

        video_container_name = os.getenv(
            "VIDEO_RECORDINGS_CONTAINER", "video-recordings")
        temp_container_name = os.getenv("TEMP_VIDEOS_CONTAINER", "temp-videos")
        sas_expiry_hours = int(os.getenv("SAS_EXPIRY_HOURS", "24"))

        # Use connection string if available, otherwise fall back to managed identity
        connection_string = os.getenv("STORAGE_CONNECTION_STRING")
        account_key = None
        if connection_string:
            blob_service_client = BlobServiceClient.from_connection_string(
                connection_string)
            # Extract account key from connection string for SAS generation
            for part in connection_string.split(';'):
                if part.startswith('AccountKey='):
                    account_key = part.split('=', 1)[1]
                    break
        else:
            managed_identity_client_id = os.getenv("AZURE_CLIENT_ID")
            credential = (
                ManagedIdentityCredential(client_id=managed_identity_client_id)
                if managed_identity_client_id
                else ManagedIdentityCredential()
            )
            account_url = f"https://{storage_account_name}.blob.core.windows.net"
            blob_service_client = BlobServiceClient(
                account_url=account_url,
                credential=credential
            )
        video_container = blob_service_client.get_container_client(
            video_container_name)

        # Optional blob prefix for subvolume path (e.g., 'video-recordings')
        blob_prefix = os.getenv("VIDEO_BLOB_PREFIX", "")

        # Prefix-based query works for all durations up to 24 hours
        # (max 25 hourly list operations). Tag-based query requires blob
        # index tags that may not be present on all recordings.
        logger.info(
            f"Using prefix-based query for {duration_seconds}s duration")
        segments = query_blobs_by_prefix(
            video_container, camera_id, start_time, end_time, blob_prefix)

        if not segments and duration_seconds > 3600:
            logger.info(
                "Prefix query returned no results, trying tag-based query")
            segments = query_blobs_by_tags(
                video_container, camera_id, start_time, end_time)

        # Apply event type filtering if specified
        if event_type_filter:
            original_count = len(segments)
            segments = filter_segments_by_event_type(
                segments, event_type_filter)
            logger.info(
                f"Filtered segments by event_type='{event_type_filter}': "
                f"{original_count} -> {len(segments)}"
            )

        if not segments:
            # Return 200 with empty results - 404 should only be for missing resources
            return func.HttpResponse(
                json.dumps({
                    "segments": [],
                    "total_segments": 0,
                    "camera_id": camera_id,
                    "start_time": start_str,
                    "end_time": end_str,
                    "event_type_filter": event_type_filter,
                    "message": "No video segments found for requested timeframe"
                }),
                status_code=200,
                mimetype="application/json"
            )

        logger.info(f"Found {len(segments)} segments for camera {camera_id}")

        if stitch:
            # Server-side stitching requested
            logger.info("Stitching segments on server")

            # Filter to only video files (exclude .json metadata files)
            video_extensions = ('.mp4', '.mkv', '.avi', '.mov')
            video_segments = [
                s for s in segments
                if s['name'].lower().endswith(video_extensions)
            ]
            logger.info(
                f"Filtered to {len(video_segments)} video files "
                f"(excluded {len(segments) - len(video_segments)} non-video files)"
            )

            if not video_segments:
                return func.HttpResponse(
                    json.dumps({
                        "error": "No video files found for stitching",
                        "camera_id": camera_id,
                        "start_time": start_str,
                        "end_time": end_str
                    }),
                    status_code=404,
                    mimetype="application/json"
                )

            # Enrich segments with JSON metadata for precise ordering and metrics
            logger.info("Enriching segments with JSON metadata")
            enriched_segments = enrich_segments_with_metadata(
                video_container, video_segments)

            # Sort by precise segment_start from metadata (falls back to filename timestamp)
            sorted_segments = sort_segments_by_metadata(enriched_segments)
            logger.info(
                f"Sorted {len(sorted_segments)} segments by metadata timestamps")

            # Detect gaps between segments
            gaps = detect_segment_gaps(sorted_segments)
            if gaps:
                logger.warning(
                    f"Detected {len(gaps)} gaps between segments: {gaps}")

            # Calculate stitch metrics from metadata
            stitch_metrics = calculate_stitch_metrics(sorted_segments)
            logger.info(f"Stitch metrics: {stitch_metrics}")

            temp_dir = Path(tempfile.mkdtemp(prefix="video_query_"))
            try:
                downloaded_files = download_segments(
                    video_container, sorted_segments, temp_dir)

                output_file = temp_dir / "merged.mp4"
                concat_segments(downloaded_files, output_file)

                merged_blob_name = (
                    f"temp/{camera_id}/"
                    f"{start_time.strftime('%Y%m%d_%H%M%S')}_"
                    f"{end_time.strftime('%Y%m%d_%H%M%S')}.mp4"
                )

                temp_container = blob_service_client.get_container_client(
                    temp_container_name)

                logger.info(f"Uploading merged video to {merged_blob_name}")
                with open(output_file, "rb") as data:
                    temp_container.upload_blob(
                        name=merged_blob_name,
                        data=data,
                        overwrite=True
                    )

                sas_url = generate_sas_url(
                    blob_service_client,
                    temp_container_name,
                    merged_blob_name,
                    sas_expiry_hours,
                    account_key
                )

                # Build enhanced response with metadata-derived metrics
                response_data = {
                    "video_url": sas_url,
                    "query_duration_seconds": duration_seconds,
                    "segment_count": len(sorted_segments),
                    "camera_id": camera_id,
                    "start_time": start_str,
                    "end_time": end_str,
                    "event_type_filter": event_type_filter,
                    "expires_at": (datetime.utcnow() + timedelta(hours=sas_expiry_hours)).isoformat(),
                    "stitched": True
                }

                # Add metadata-derived stitch metrics
                if stitch_metrics.get("total_duration_seconds"):
                    response_data["actual_duration_seconds"] = stitch_metrics["total_duration_seconds"]
                if stitch_metrics.get("earliest_segment_start"):
                    response_data["earliest_segment_start"] = stitch_metrics["earliest_segment_start"]
                if stitch_metrics.get("latest_segment_end"):
                    response_data["latest_segment_end"] = stitch_metrics["latest_segment_end"]
                if stitch_metrics.get("locations"):
                    response_data["locations"] = stitch_metrics["locations"]
                response_data["metadata_coverage"] = round(
                    stitch_metrics.get("metadata_coverage", 0) * 100, 1)

                # Include gap warnings if any detected
                if gaps:
                    response_data["gaps"] = gaps
                    response_data["gap_count"] = len(gaps)
                    response_data["total_gap_seconds"] = round(
                        sum(g["gap_seconds"] for g in gaps), 2)

                logger.info(
                    f"Video query completed successfully for camera {camera_id}")

                return func.HttpResponse(
                    json.dumps(response_data),
                    status_code=200,
                    mimetype="application/json"
                )

            finally:
                import shutil
                try:
                    shutil.rmtree(temp_dir)
                    logger.info(f"Cleaned up temporary directory: {temp_dir}")
                except Exception as e:
                    logger.warning(
                        f"Failed to cleanup temporary directory {temp_dir}: {e}")
        else:
            # Return individual segments (default)
            segment_urls = []
            for segment in segments:
                sas_url = generate_sas_url(
                    blob_service_client,
                    video_container_name,
                    segment["name"],
                    sas_expiry_hours,
                    account_key
                )
                recording_type, specific_event = detect_recording_type(
                    segment["name"])

                # Fetch companion JSON metadata for enriched response
                metadata = fetch_segment_metadata(
                    video_container, segment["name"])

                segment_data = {
                    "url": sas_url,
                    "name": segment["name"],
                    "timestamp": segment["timestamp"].isoformat() if segment["timestamp"] else None,
                    "size_bytes": segment.get("size"),
                    "recording_type": recording_type,
                    "event_type": specific_event
                }

                # Enrich with metadata fields if available
                if metadata:
                    segment_data["duration_seconds"] = metadata.get(
                        "duration_seconds")
                    segment_data["location"] = metadata.get("location")
                    segment_data["segment_start"] = metadata.get(
                        "segment_start")
                    segment_data["segment_end"] = metadata.get("segment_end")

                segment_urls.append(segment_data)

            response_data = {
                "segments": segment_urls,
                "total_segments": len(segments),
                "camera_id": camera_id,
                "start_time": start_str,
                "end_time": end_str,
                "event_type_filter": event_type_filter,
                "expires_at": (
                    datetime.utcnow() + timedelta(hours=sas_expiry_hours)
                ).isoformat(),
                "stitched": False
            }

            logger.info(
                f"Video query completed successfully for camera {camera_id}")

            return func.HttpResponse(
                json.dumps(response_data),
                status_code=200,
                mimetype="application/json"
            )

    except Exception as e:
        logger.exception("Unexpected error processing video query")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )


@app.route(route="trigger", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def trigger_capture(req: func.HttpRequest) -> func.HttpResponse:
    """Trigger a video capture event via Event Grid MQTT."""
    camera = req.params.get("camera", "pmn-camera-01-triggered")

    if camera not in ALLOWED_CAMERAS:
        return func.HttpResponse(
            json.dumps({"error": f"Invalid camera: {camera}", "allowed": sorted(ALLOWED_CAMERAS)}),
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
    trigger_payload = json.dumps({
        "Alert": True,
        "attributes": {
            "devices": [{
                "device_data": {
                    "type": "ALERT_DLQC",
                    "timestamp": timestamp_ms,
                    "event_id": event_id,
                }
            }]
        },
    })

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
            topic="alerts/trigger",
            payload=trigger_payload,
        )
    except Exception as e:
        logging.exception("MQTT trigger publish failed")
        return func.HttpResponse(
            json.dumps({"error": "Trigger delivery failed"}),
            status_code=502,
            mimetype="application/json",
        )

    _trigger_rate_limits[camera] = now

    return func.HttpResponse(
        json.dumps({
            "status": "accepted",
            "camera": camera,
            "event_id": event_id,
            "timestamp": timestamp_ms,
            "estimated_ready_seconds": 120,
            "message": f"Trigger sent for {camera}. Video should be queryable in ~2 minutes.",
        }),
        status_code=202,
        mimetype="application/json",
    )
