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
* **Optimized Blob Filtering**: Prefix-based list queries for windows up to 24 hours
  * Falls back to blob index tag queries when a window over 1 hour returns no prefix matches
  * See `query_blobs_by_prefix` and `query_blobs_by_tags` in `function_app.py`
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
* Managed Identity with Storage Blob Data Contributor role
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
      "segment_end": "2026-01-13T21:47:09.123456+00:00"
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

> **Note**: The `duration_seconds`, `location`, `segment_start`, and `segment_end` fields are populated from companion JSON metadata files when available. These fields provide precise timing information from the recording service.

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
  "stitched": true
}
```

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

| Status | Description                                                                      |
|--------|----------------------------------------------------------------------------------|
| 200    | Success — segments found or empty result with message                            |
| 202    | Accepted — trigger capture request accepted (POST /api/trigger)                  |
| 400    | Bad Request — missing/invalid parameters or disallowed camera                    |
| 404    | Not Found — stitch requested but no video files found                            |
| 429    | Too Many Requests — trigger rate limited (30-second per-camera)                  |
| 500    | Internal Server Error — storage connection or processing failure                 |
| 502    | Bad Gateway — MQTT trigger delivery failed                                       |
| 503    | Service Unavailable — trigger or Event Grid not configured, or storage not ready |

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

**Behavior:** Publishes an `ALERT_DLQC` event with the camera ID to the Event Grid Namespace MQTT broker (port 8883, MQTTv5, TLS) on topic `alerts/trigger/{camera}`. Authenticates with a managed identity token through MQTT v5 enhanced authentication (`OAUTH2-JWT`) and returns `502` when the connection is refused or the publish isn't acknowledged. Enforces a 30-second per-camera rate limit.

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

* `STORAGE_ACCOUNT_NAME`: Azure Storage account name
* `VIDEO_RECORDINGS_CONTAINER`: Container name for video segments (default: "video-recordings")
* `TEMP_VIDEOS_CONTAINER`: Container name for merged videos (default: "temp-videos", required only for stitch=true)
* `SAS_EXPIRY_HOURS`: SAS token expiry in hours (default: "24")
* `FFMPEG_PATH`: Path to an ffmpeg binary, used only when `bin/ffmpeg` isn't bundled with the app (default: "ffmpeg", required only for stitch=true)
* `STITCH_MAX_DURATION_SECONDS`: Longest window that `stitch=true` accepts (default: "3600")
* `EVENT_GRID_HOSTNAME`: Event Grid Namespace MQTT hostname (required for trigger endpoint)
* `TRIGGER_ALLOWED_CAMERAS`: Comma-separated camera IDs the trigger endpoint accepts. Entries must contain only letters, digits, underscores, and hyphens. The trigger endpoint is disabled when this is empty
* `AZURE_CLIENT_ID`: Client ID of a user-assigned managed identity. Omit it to use the system-assigned identity
* `MQTT_CLIENT_ID`: MQTT client ID for trigger publishing (default: "video-query-trigger")

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

   # Grant Storage Blob Data Contributor role
   az role assignment create \
     --assignee <function-app-principal-id> \
     --role "Storage Blob Data Contributor" \
     --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>
   ```

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

## Query Optimization

The handler lists blobs by the hourly path prefix `{camera_id}/{YYYY}/{MM}/{DD}/{HH}/` for every window up to 24 hours. When a window longer than 1 hour returns no prefix matches, it falls back to a blob index tag query on `camera_id`, `start_time`, and `end_time`, which needs recordings that carry those tags. See `query_blobs_by_prefix` and `query_blobs_by_tags` in `function_app.py`.

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
* A window no longer than `STITCH_MAX_DURATION_SECONDS` (default 1 hour)

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

### "Blob storage connection failed"

* Verify connection string is correct
* Check firewall rules allow Function App to access Storage
* Verify container names match configuration

### "Authentication failed"

* Verify Azure credentials are configured
* Check RBAC permissions for Storage account
* Ensure Function App has Storage Blob Data Contributor role

## Cost Considerations

* **Function Execution**: Consumption plan charges per execution; segment queries are short, while `stitch=true` runs longer because it downloads and concatenates video
* **Storage**: Cool tier recommended for segments older than 30 days
* **Egress**: SAS URLs enable direct client downloads (no Function egress)
* **Temporary Storage**: Segment queries store nothing extra; `stitch=true` writes a stitched blob to `TEMP_VIDEOS_CONTAINER`

## Security

* Function-level authentication is required for `/api/video`, `/api/ready`, and `/api/trigger`; only the `/api/health` liveness probe is anonymous, and it returns no configuration details
* Camera IDs are validated against an allowlist pattern before they're used in blob paths or blob index tag filters
* The trigger endpoint accepts only cameras listed in `TRIGGER_ALLOWED_CAMERAS`
* Error responses don't include exception details
* Python dependencies are pinned with hashes, and the ffmpeg download is pinned and SHA-256 verified
* SAS URLs use read-only permissions
* SAS links expire after `SAS_EXPIRY_HOURS`; stitched videos in `TEMP_VIDEOS_CONTAINER` persist until removed, so configure a [lifecycle management rule](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview) to delete them
* Connection strings stored in Key Vault (recommended)

## Contributing

Follow repository contribution guidelines when modifying this component.

## Related Components

* **503-media-capture-service**: Continuous recording service that produces segments
