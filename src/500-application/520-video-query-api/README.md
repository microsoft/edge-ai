---
title: Video Query API
description: Azure Function for querying and retrieving time-based video segments from continuous camera recordings
author: Edge AI Team
ms.date: 2026-10-05
ms.topic: reference
keywords:
  - video-query
  - azure-function
  - blob-storage
  - time-based-query
  - sas-urls
estimated_reading_time: 10
---

## Video Query API

Azure Function for querying and retrieving time-based video segments from continuous camera recordings. Enables data scientists and analysts to request video from specific cameras for specific timeframes, with secure SAS URL generation for direct segment access.

## Overview

The Video Query API provides a REST endpoint for querying video recordings stored in Azure Blob Storage. It supports efficient time-based queries using optimized blob filtering strategies and generates secure SAS URLs for direct segment downloads.

## Features

* **Time-Based Video Queries**: Query videos by camera ID and timestamp range (start/end)
* **Overlap-Based Discovery**: Lists the hourly prefixes the 503 media capture service writes and returns every recording whose footage overlaps the window, including recordings that started before it. See [Discovery](#discovery)
* **Individual Segment Access**: Returns array of video segments with metadata
* **MQTT-Triggered Capture**: Trigger on-demand video capture via Event Grid MQTT
* **Health Monitoring**: Anonymous liveness endpoint and key-protected storage readiness endpoint
* **Secure Access**: SAS URL generation with configurable expiry (default: 24 hours)
* **Managed Identity Auth**: Uses Azure Managed Identity for storage access and MQTT publishing

## Architecture

```text
┌──────────────┐      HTTP GET      ┌─────────────────────┐
│ Data         │ ─────────────────> │ Video Query API     │
│ Scientist    │  /api/video?       │ (Azure Function)    │
│              │   camera=xxx&      │                     │
│              │   start=2026-01&   │ Endpoints:          │
│              │   end=2026-01      │  GET  /api/health   │
│              │                    │  GET  /api/ready    │
└──────────────┘                    │  GET  /api/video    │
       ^                            │  POST /api/trigger  │
       │                            └─────────────────────┘
       │ Array of                        │            │
       │ Segment URLs                    │ Query      │ MQTT Publish
       │ (24h expiry)                    │            │ (alerts/trigger/{camera})
       └─────────────────────────────────┘            │
                                             │        │
                                    ┌────────▼───┐  ┌─▼──────────────┐
                                    │ Azure Blob │  │ Event Grid     │
                                    │ Storage    │  │ Namespace      │
                                    │            │  │ (MQTT :8883)   │
                                    │ • video-   │  └────────────────┘
                                    │   recordings│
                                    └────────────┘
```

## Prerequisites

* Azure subscription with appropriate permissions
* Azure Blob Storage account with containers:
  * `video-recordings`: Continuous recording segments
  * `temp-videos`: Temporary merged video storage (required only for stitch=true)
* Azure Functions Core Tools 4.x
* Python 3.11 or later
* Managed identity with the storage roles in [Deploy to Azure Functions](#deploy-to-azure-functions)
* Recordings written by the `503-media-capture-service` continuous recording mode, or in the same layout
* FFmpeg 4.4 or later (required only for stitch=true)

## API Reference

### GET /api/health

Liveness probe. It performs no storage access and returns no configuration details.

**Auth Level:** Anonymous (no key required)

**Response (HTTP 200):**

```json
{"status": "healthy"}
```

### GET /api/ready

Readiness probe that verifies access to the video recordings container.

**Auth Level:** Function (API key required via `code` parameter)

**Response (ready, HTTP 200):**

```json
{"status": "ready"}
```

**Response (not ready, HTTP 503):**

```json
{"status": "not_ready"}
```

Failure details are written to the function log and are never returned to the caller.

### GET /api/video

Query and retrieve video for a specific camera and timeframe.

**Query Parameters:**

* `camera` (required): Camera ID containing only letters, digits, underscores, and hyphens (e.g., "camera-01")
* `start` (required): Start timestamp in ISO 8601 UTC format (e.g., "2026-01-20T10:00:00Z")
* `end` (required): End timestamp in ISO 8601 UTC format (e.g., "2026-01-20T10:30:00Z")
* `event_type` (optional): Filter by recording type — "continuous", "triggered", or specific event (e.g., "alert")
* `stitch` (optional): Set to "true" to concatenate segments on server (default: "false")

> **Note:** Always use UTC timestamps with the `Z` suffix for consistent results.

**Response (with stitch=false or omitted, default):**

```json
{
  "segments": [
    {
      "url": "https://storage.blob.core.windows.net/video-recordings/...",
      "name": "camera-01/2026/01/13/21/segment_2026-01-13T21:42:09Z_camera-01.mp4",
      "timestamp": "2026-01-13T21:42:09+00:00",
      "size_bytes": 36175872,
      "recording_type": "continuous",
      "event_type": null,
      "duration_seconds": 300,
      "location": "plant-a",
      "segment_start": "2026-01-13T21:42:09.123456+00:00",
      "segment_end": "2026-01-13T21:47:09.123456+00:00",
      "timing": "metadata"
    }
  ],
  "total_segments": 1,
  "camera_id": "camera-01",
  "start_time": "2026-01-13T21:40:00Z",
  "end_time": "2026-01-13T21:45:00Z",
  "expires_at": "2026-01-15T06:10:04.068612",
  "stitched": false
}
```

> **Note**: The `duration_seconds`, `location`, `segment_start`, and `segment_end` fields come from the companion JSON metadata file when it's available. `timing` is `metadata` when the footage interval came from that file and `filename` when only the time in the file name was available, such as for triggered clips.

**Response (with stitch=true):**

```json
{
  "video_url": "https://storage.blob.core.windows.net/temp-videos/...",
  "query_duration_seconds": 300,
  "actual_duration_seconds": 298.5,
  "segment_count": 6,
  "camera_id": "camera-01",
  "start_time": "2026-01-13T21:40:00Z",
  "end_time": "2026-01-13T21:45:00Z",
  "earliest_segment_start": "2026-01-13T21:40:02.123456+00:00",
  "latest_segment_end": "2026-01-13T21:44:58.789012+00:00",
  "locations": ["plant-a"],
  "metadata_coverage": 100.0,
  "expires_at": "2026-01-15T06:10:04.068612",
  "stitched": true,
  "trimmed": false
}
```

Recordings are returned whole, so stitched video isn't trimmed to the window. `earliest_segment_start` and `latest_segment_end` report the footage it actually covers. Each stitched result is written once under a unique name, so a SAS URL that's already been shared keeps returning the same video.

**Stitch Response with Gaps Detected:**

When gaps between video segments exceed 5 seconds, the response includes gap details:

```json
{
  "video_url": "https://storage.blob.core.windows.net/temp-videos/...",
  "query_duration_seconds": 600,
  "actual_duration_seconds": 580.5,
  "segment_count": 12,
  "camera_id": "camera-01",
  "start_time": "2026-01-13T21:40:00Z",
  "end_time": "2026-01-13T21:50:00Z",
  "gaps": [
    {
      "after_segment": "camera-01/2026/01/13/21/segment_003.mp4",
      "before_segment": "camera-01/2026/01/13/21/segment_004.mp4",
      "gap_start": "2026-01-13T21:42:30.000000+00:00",
      "gap_end": "2026-01-13T21:42:45.500000+00:00",
      "gap_seconds": 15.5
    }
  ],
  "gap_count": 1,
  "total_gap_seconds": 15.5,
  "metadata_coverage": 100.0,
  "stitched": true
}
```

> **Note**: Gap detection uses precise `segment_start` and `segment_end` timestamps from JSON metadata. Segments are ordered by metadata timestamps for accurate concatenation. The `metadata_coverage` field indicates what percentage of segments had companion JSON metadata available.

### HTTP Response Codes

| Status | Description                                                                     |
|--------|---------------------------------------------------------------------------------|
| 200    | Success — segments found or empty result with message                           |
| 202    | Accepted — trigger capture request accepted (POST /api/trigger)                 |
| 400    | Bad Request — invalid parameters, disallowed camera, or stitch job over a limit |
| 429    | Too Many Requests — trigger rate limited, or every stitch slot is busy          |
| 500    | Internal Server Error — storage not configured or processing failure            |
| 502    | Bad Gateway — recording discovery or retrieval failed, or MQTT delivery failed  |
| 503    | Service Unavailable — not configured, storage not ready, or short on disk space |
| 504    | Gateway Timeout — stitching didn't finish within `STITCH_DEADLINE_SECONDS`      |

A failed or interrupted blob listing returns `502` instead of an empty or partial result. A missing metadata file isn't an error; the segment is returned with `timing: "filename"`.

**Empty Results Response (HTTP 200):**

```json
{
  "segments": [],
  "total_segments": 0,
  "message": "No video segments found for camera 'camera-01' between 2026-01-20T10:00:00Z and 2026-01-20T10:30:00Z",
  "camera_id": "camera-01",
  "start_time": "2026-01-20T10:00:00Z",
  "end_time": "2026-01-20T10:30:00Z"
}
```

**Bad Request Response (HTTP 400):**

```json
{
  "error": "Missing required parameter: camera"
}
```

**Example Requests:**

```bash
# Get individual segments (default, fast)
curl "https://<function-app-name>.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&code=<KEY>"

# Get stitched video (requires ffmpeg)
curl "https://<function-app-name>.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true&code=<KEY>"
```

### POST /api/trigger

Trigger an on-demand video capture event via Event Grid MQTT.

**Auth Level:** Function (API key required via `code` parameter)

**Query Parameters:**

* `camera` (required): Camera ID. Must appear in the `TRIGGER_ALLOWED_CAMERAS` app setting.

The trigger endpoint is disabled until `TRIGGER_ALLOWED_CAMERAS` lists at least one camera ID.

**Behavior:** Publishes an `ALERT_DLQC` event with the camera ID to the Event Grid Namespace MQTT broker (port 8883, MQTTv5, TLS) on topic `alerts/trigger/{camera}`. Authenticates with a managed identity token through MQTT v5 enhanced authentication (`OAUTH2-JWT`). Returns `502` when the connection is refused, the publish isn't acknowledged, or the PUBACK carries a failure reason code such as Not authorized; a failed trigger doesn't start the rate limit. Enforces a 30-second per-camera rate limit.

Each request connects with a unique client ID, `{MQTT_CLIENT_ID}-{random suffix}`, so concurrent requests and scaled-out instances don't replace each other's sessions. Event Grid allows one session per authentication name by default, so set **Maximum client sessions per authentication name** on the namespace to the number of concurrent triggers you expect.

Configure each `503-media-capture-service` instance to subscribe to its own camera's topic, for example `TRIGGER_TOPICS=["alerts/trigger/camera-01"]`. The function identity needs the **EventGrid TopicSpaces Publisher** role on a topic space that includes `alerts/trigger/#`.

The rate limit is kept in memory per function instance, so it doesn't hold across scaled-out instances or restarts. Treat it as a guard against accidental repeats, not a strict limit.

**Success Response (HTTP 202):**

```json
{
  "status": "accepted",
  "camera": "camera-01-triggered",
  "event_id": 123456,
  "timestamp": 1738368000000,
  "estimated_ready_seconds": 120,
  "message": "Trigger sent for camera-01-triggered. Video should be queryable in ~2 minutes."
}
```

**Error Responses:**

```json
// 400 — camera missing or not in TRIGGER_ALLOWED_CAMERAS
{"error": "Invalid camera"}

// 429 — rate limited
{"error": "Rate limited", "retry_after_seconds": 25, "camera": "camera-01-triggered"}

// 502 — MQTT publish failed
{"error": "Trigger delivery failed"}

// 503 — TRIGGER_ALLOWED_CAMERAS empty or not set
{"error": "Trigger not configured"}

// 503 — Event Grid not configured
{"error": "Event Grid not configured", "detail": "EVENT_GRID_HOSTNAME not set"}
```

**Example Request:**

```bash
curl -X POST "https://<function-app-name>.azurewebsites.net/api/trigger?camera=camera-01-triggered&code=<KEY>"
```

## Local Development

### Quick Start

1. Clone and navigate to the component:

   ```bash
   cd src/500-application/520-video-query-api
   ```

2. Copy and configure local settings:

   ```bash
   cp local.settings.json.example local.settings.json
   nano local.settings.json
   ```

3. Install dependencies:

   ```bash
   pip install --require-hashes -r requirements.txt
   ```

   `requirements.txt` is generated from `requirements.in` with hashes. After changing `requirements.in`, regenerate it with the command in that file's header.

4. Start the function locally:

   ```bash
   func start
   ```

5. Test the endpoint:

   ```bash
   curl "http://localhost:7071/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z"
   ```

### Environment Configuration

Required environment variables:

* `STORAGE_ACCOUNT_NAME`: Azure Storage account name, accessed with the managed identity
* `STORAGE_CONNECTION_STRING`: Alternative to `STORAGE_ACCOUNT_NAME` for local development. It must carry an account key (`AccountKey`, or `UseDevelopmentStorage=true` for Azurite) to sign SAS URLs; SAS-token connection strings aren't supported
* `VIDEO_BLOB_PREFIX`: Path prefix in front of `{camera}/` in blob names (default: none)
* `SEGMENT_LOOKBACK_SECONDS`: How far before the window discovery looks for recordings that started earlier (default: "3900", the longest 503 segment plus its grace period)
* `VIDEO_RECORDINGS_CONTAINER`: Container name for video segments (default: "video-recordings")
* `TEMP_VIDEOS_CONTAINER`: Container name for merged videos (default: "temp-videos", required only for stitch=true)
* `SAS_EXPIRY_HOURS`: SAS token expiry in hours (default: "24")
* `FFMPEG_PATH`: Path to an ffmpeg binary, used only when `bin/ffmpeg` isn't bundled with the app (default: "ffmpeg", required only for stitch=true)
* `STITCH_MAX_DURATION_SECONDS`: Longest window that `stitch=true` accepts (default: "3600")
* `STITCH_MAX_SEGMENTS`: Most segments one stitch job accepts (default: "120")
* `STITCH_MAX_BYTES`: Most input bytes one stitch job accepts (default: "2147483648")
* `STITCH_DEADLINE_SECONDS`: Time from request start after which a stitch job stops (default: "200", under the 230-second HTTP limit)
* `STITCH_MAX_CONCURRENT`: Stitch jobs each instance runs at once (default: "1")
* `EVENT_GRID_HOSTNAME`: Event Grid Namespace MQTT hostname (required for trigger endpoint)
* `TRIGGER_ALLOWED_CAMERAS`: Comma-separated camera IDs the trigger endpoint accepts. Entries must contain only letters, digits, underscores, and hyphens. The trigger endpoint is disabled when this is empty
* `AZURE_CLIENT_ID`: Client ID of a user-assigned managed identity. Omit it to use the system-assigned identity
* `MQTT_CLIENT_ID`: Prefix for the unique MQTT client ID of each trigger publish (default: "video-query-trigger")

## Production Deployment

### Deploy to Azure Functions

1. Create Azure Function App:

   ```bash
   az functionapp create \
     --name video-query-func \
     --resource-group rg-edge-ai \
     --consumption-plan-location eastus \
     --runtime python \
     --runtime-version 3.11 \
     --functions-version 4 \
     --storage-account <functions-storage-account>
   ```

2. Enable managed identity and grant storage access:

   ```bash
   # Enable system-assigned managed identity
   az functionapp identity assign \
     --name video-query-func \
     --resource-group rg-edge-ai

   STORAGE_ID=/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>

   # Read recordings
   az role assignment create \
     --assignee <function-app-principal-id> \
     --role "Storage Blob Data Reader" \
     --scope "${STORAGE_ID}/blobServices/default/containers/video-recordings"

   # Request user delegation keys to sign SAS URLs
   az role assignment create \
     --assignee <function-app-principal-id> \
     --role "Storage Blob Delegator" \
     --scope "${STORAGE_ID}"

   # Write stitched videos (required only for stitch=true)
   az role assignment create \
     --assignee <function-app-principal-id> \
     --role "Storage Blob Data Contributor" \
     --scope "${STORAGE_ID}/blobServices/default/containers/temp-videos"
   ```

   A user delegation SAS grants no more than its signer can do, so these roles also bound what the SAS URLs allow.

3. Configure application settings:

   ```bash
   az functionapp config appsettings set \
     --name video-query-func \
     --resource-group rg-edge-ai \
     --settings \
       STORAGE_ACCOUNT_NAME="<storage-account-name>" \
       VIDEO_RECORDINGS_CONTAINER="video-recordings" \
       TEMP_VIDEOS_CONTAINER="temp-videos" \
       SAS_EXPIRY_HOURS="24"
   ```

4. Bundle ffmpeg with the app (required only for stitch=true):

   ```bash
   # Option 1: Download a pinned static build into bin/ffmpeg before publishing.
   # The script verifies the archive's SHA-256 before installing. Override
   # FFMPEG_VERSION and FFMPEG_SHA256 together to change versions.
   ./install-ffmpeg.sh

   # Option 2: Use a custom container with ffmpeg pre-installed
   # See https://learn.microsoft.com/azure/azure-functions/functions-how-to-custom-container
   ```

   `stitch=true` uses `bin/ffmpeg` next to `function_app.py` when it exists, and the `.funcignore` file keeps it in the deployment package. Run the script on a Linux x86-64 machine or in your build pipeline before `func azure functionapp publish`.

5. Deploy the function:

   ```bash
   func azure functionapp publish video-query-func
   ```

6. (Optional) Test stitching functionality:

   ```bash
   func azure functionapp publish video-query-func

   # Test without stitching (fast)
   curl "https://video-query-func.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z"

   # Test with stitching (requires ffmpeg)
   curl "https://video-query-func.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true"
   ```

## Performance

* **Query Time**: < 1 second for queries up to 1 hour
* **SAS Generation**: < 100ms per segment
* **Response Time (stitch=false)**: < 2 seconds for typical queries (up to 100 segments)
* **Response Time (stitch=true)**: 2-10 seconds depending on segment count and duration. HTTP-triggered functions [time out after 230 seconds](https://learn.microsoft.com/azure/azure-functions/functions-scale#timeout) at the load balancer, so `stitch=true` accepts windows up to `STITCH_MAX_DURATION_SECONDS` (default 1 hour)
* **Stitching Time**: ~500ms for 30-minute video (no re-encoding)
* **Storage Efficiency**: Hierarchical blob paths enable optimal distribution

## Discovery

The API reads the layout the `503-media-capture-service` writes:

* Continuous segments: `{camera}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera}.{ext}`, each with a JSON metadata file holding `segment_start` and `segment_end`
* Triggered clips: `{camera}/{YYYY}/{MM}/{DD}/{HH}/{YYYY-MM-DD}_{HHMMSS}_..._{event}_id_{id}.{ext}`, without a metadata file

For each request, the handler:

1. Lists the hourly prefixes from `SEGMENT_LOOKBACK_SECONDS` before the window up to its end, so recordings that started earlier are found.
2. Applies the `event_type` filter.
3. Reads each candidate's metadata file and keeps it when its footage overlaps the window: `segment_start < end` and `segment_end > start`.
4. Keeps a recording without usable metadata only when the time in its file name falls inside the window, and marks it `timing: "filename"`. For triggered clips that time is when the clip was written, so it's approximate.

See `query_blobs_by_prefix` and `select_overlapping_segments` in `function_app.py`.

## Stitching vs Segments

Choose the appropriate response format based on your use case:

### Use stitch=false (default, recommended)

**Best for:**

* Fast response times (< 2 seconds)
* Programmatic access to individual segments
* Parallel downloads
* Analyzing specific time ranges
* Maximum flexibility

**Example:**

```bash
curl "https://func.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z"
```

**Response:** Array of segment URLs with metadata

**Client-side concatenation (if needed):**

```bash
# Download segments
for url in $(cat response.json | jq -r '.segments[].url'); do
  wget "$url"
done

# Concatenate with ffmpeg
ffmpeg -f concat -safe 0 -i segments.txt -c copy merged.mp4
```

### Use stitch=true

**Best for:**

* Single video file output
* Users without ffmpeg/technical tools
* Direct playback in simple video players
* Simplified downstream processing

**Requirements:**

* FFmpeg bundled with the Function App (see `install-ffmpeg.sh`)
* `temp-videos` container for temporary storage, with a lifecycle management rule that deletes stitched videos
* Slower response time (2-10 seconds)
* Segments of one recording type with matching codec settings; set `event_type` when a window holds both continuous and triggered recordings
* A job within the stitch limits:
  * A window no longer than `STITCH_MAX_DURATION_SECONDS` (default 1 hour)
  * At most `STITCH_MAX_SEGMENTS` segments and `STITCH_MAX_BYTES` of input, checked before anything is downloaded
  * Free temporary storage for about twice the input size, because inputs and the merged output coexist
  * A free slot out of `STITCH_MAX_CONCURRENT` per instance; otherwise the request returns `429`
  * Completion within `STITCH_DEADLINE_SECONDS` of the request starting; otherwise it returns `504`

For longer jobs, request segments and concatenate them on the client, or move stitching to an asynchronous pattern such as [Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-http-features#async-operation-tracking).

**Example:**

```bash
curl "https://func.azurewebsites.net/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true"
```

**Response:** Single `video_url` pointing to merged MP4 file

## Troubleshooting

### "Video not available for requested timeframe"

* Verify continuous recording is enabled on edge device
* Check if timeframe is within ring buffer window (if using ring buffer only mode)
* Verify blob storage connection and container exists

### "Recording discovery failed" (HTTP 502)

* Check the Function App logs for the listing or metadata error
* Check firewall rules allow the Function App to access Storage
* Verify the identity has **Storage Blob Data Reader** on the recordings container

### "Storage connection not configured" (HTTP 500)

* Set `STORAGE_ACCOUNT_NAME`, or a `STORAGE_CONNECTION_STRING` that includes an account key
* Verify container names match configuration

### "Authentication failed"

* Verify Azure credentials are configured
* Check the role assignments in [Deploy to Azure Functions](#deploy-to-azure-functions)

## Cost Considerations

* **Function Execution**: Consumption plan charges per execution; segment queries are short, while `stitch=true` runs longer because it downloads and concatenates video
* **Storage**: Cool tier recommended for segments older than 30 days
* **Egress**: SAS URLs enable direct client downloads (no Function egress)
* **Temporary Storage**: Segment queries store nothing extra; `stitch=true` writes a stitched blob to `TEMP_VIDEOS_CONTAINER`

## Security

* Function-level authentication is required for `/api/video`, `/api/ready`, and `/api/trigger`; only the `/api/health` liveness probe is anonymous, and it returns no configuration details
* Trust model: callers authenticate with a Function key, not their own identity. Returned SAS URLs are authorized by the Function App's identity, so anyone with a key can read any camera's recordings in the configured container. Share keys accordingly, or put an API gateway with per-caller authorization in front of the API
* Camera IDs are validated against an allowlist pattern before they're used in blob paths or MQTT topics
* The trigger endpoint accepts only cameras listed in `TRIGGER_ALLOWED_CAMERAS`
* Error responses don't include exception details
* Python dependencies are pinned with hashes, and the ffmpeg download is pinned and SHA-256 verified
* SAS URLs use read-only permissions
* SAS links expire after `SAS_EXPIRY_HOURS`; stitched videos in `TEMP_VIDEOS_CONTAINER` persist until removed, so configure a [lifecycle management rule](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview) to delete them
* Connection strings stored in Key Vault (recommended)

## Testing

Unit tests need no Azure resources and run in CI through the `python-tests` workflow:

```bash
pip install --require-hashes -r requirements.txt -r requirements-test.txt
pytest -m "not integration"
```

The deployed suite in `tests/test_video_query_api.py` seeds recordings in the 503 layout for a unique camera, queries a running API, downloads and inspects the stitched result, and deletes what it seeded. It runs when `VIDEO_QUERY_API_ENDPOINT` is set, and then fails, rather than skips, when the API, `VIDEO_QUERY_API_CODE`, seeding storage access, or ffmpeg is missing:

```bash
export VIDEO_QUERY_API_ENDPOINT="https://<function-app-name>.azurewebsites.net"
export VIDEO_QUERY_API_CODE="<function-key>"
export VIDEO_QUERY_TEST_STORAGE_ACCOUNT="<storage-account>"  # or VIDEO_QUERY_TEST_STORAGE_CONNECTION_STRING
pytest -m integration
```

## Contributing

Follow repository contribution guidelines when modifying this component.

## Related Components

* **503-media-capture-service**: Records the segments and triggered clips this API queries; see [Discovery](#discovery) for the layout
