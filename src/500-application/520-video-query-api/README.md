---
title: Video Query API
description: Azure Function for querying and retrieving time-based video segments from continuous camera recordings
author: Edge AI Team
ms.date: 2026-03-03
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
* **Optimized Blob Filtering**: Automatic query optimization based on duration
  * < 1 hour: Prefix-based list queries (fastest)
  * 1-24 hours: Blob index tag queries (efficient)
* **Individual Segment Access**: Returns array of video segments with metadata
* **MQTT-Triggered Capture**: Trigger on-demand video capture via Event Grid MQTT
* **Health Monitoring**: Anonymous health endpoint for storage connectivity checks
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
└──────────────┘                    │  GET  /api/video    │
       ^                            │  POST /api/trigger  │
       │                            └─────────────────────┘
       │ Array of                        │            │
       │ Segment URLs                    │ Query      │ MQTT Publish
       │ (24h expiry)                    │            │ (alerts/trigger)
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

Anonymous health check that tests blob storage connectivity.

**Auth Level:** Anonymous (no key required)

**Response (healthy):**

```json
{
  "status": "healthy",
  "storage_account": "stvideoqueryapipoc001",
  "container": "video-recordings",
  "blob_prefix": "",
  "blobs_found": 5,
  "sample_blobs": ["..."],
  "auth_method": "managed_identity"
}
```

**Response (unhealthy, HTTP 500):**

```json
{
  "status": "unhealthy",
  "error": "...",
  "storage_account": "stvideoqueryapipoc001",
  "container": "video-recordings"
}
```

### GET /api/video

Query and retrieve video for a specific camera and timeframe.

**Query Parameters:**

* `camera` (required): Camera ID (e.g., "pmn-camera-01")
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
      "name": "reolink-01/2026/01/13/21/segment_2026-01-13T21:42:09Z_reolink-01.mp4",
      "timestamp": "2026-01-13T21:42:09+00:00",
      "size_bytes": 36175872,
      "recording_type": "continuous",
      "event_type": null,
      "duration_seconds": 300,
      "location": "PMN-Plant",
      "segment_start": "2026-01-13T21:42:09.123456+00:00",
      "segment_end": "2026-01-13T21:47:09.123456+00:00"
    }
  ],
  "total_segments": 1,
  "camera_id": "reolink-01",
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
  "camera_id": "reolink-01",
  "start_time": "2026-01-13T21:40:00Z",
  "end_time": "2026-01-13T21:45:00Z",
  "earliest_segment_start": "2026-01-13T21:40:02.123456+00:00",
  "latest_segment_end": "2026-01-13T21:44:58.789012+00:00",
  "locations": ["PMN-Plant"],
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
  "camera_id": "reolink-01",
  "start_time": "2026-01-13T21:40:00Z",
  "end_time": "2026-01-13T21:50:00Z",
  "gaps": [
    {
      "after_segment": "reolink-01/2026/01/13/21/segment_003.mp4",
      "before_segment": "reolink-01/2026/01/13/21/segment_004.mp4",
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

| Status | Description                                                          |
|--------|----------------------------------------------------------------------|
| 200    | Success — segments found or empty result with message                |
| 202    | Accepted — trigger capture request accepted (POST /api/trigger)      |
| 400    | Bad Request — missing/invalid parameters or disallowed camera        |
| 404    | Not Found — stitch requested but no video files found                |
| 429    | Too Many Requests — trigger rate limited (30-second per-camera)      |
| 500    | Internal Server Error — storage connection or processing failure     |
| 502    | Bad Gateway — MQTT trigger delivery failed                           |
| 503    | Service Unavailable — Event Grid not configured                      |

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
curl "https://func-video-query-poc-001.azurewebsites.net/api/video?camera=pmn-camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&code=<KEY>"

# Get stitched video (requires ffmpeg)
curl "https://func-video-query-poc-001.azurewebsites.net/api/video?camera=pmn-camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true&code=<KEY>"
```

### POST /api/trigger

Trigger an on-demand video capture event via Event Grid MQTT.

**Auth Level:** Function (API key required via `code` parameter)

**Query Parameters:**

* `camera` (optional): Camera ID (default: "pmn-camera-01-triggered"). Must be one of:
  * `pmn-camera-01-triggered`
  * `pmn-camera-02-triggered`
  * `pmn-camera-03-triggered`
  * `pmn-camera-04-triggered`

**Behavior:** Publishes an `ALERT_DLQC` event to the Event Grid Namespace MQTT broker (port 8883, MQTTv5, TLS) on topic `alerts/trigger`. Uses managed identity OAuth authentication. Enforces a 30-second per-camera rate limit.

**Success Response (HTTP 202):**

```json
{
  "status": "accepted",
  "camera": "pmn-camera-01-triggered",
  "event_id": 123456,
  "timestamp": 1738368000000,
  "estimated_ready_seconds": 120,
  "message": "Trigger sent for pmn-camera-01-triggered. Video should be queryable in ~2 minutes."
}
```

**Error Responses:**

```json
// 400 — invalid camera
{"error": "Invalid camera: bad-cam", "allowed": ["pmn-camera-01-triggered", ...]}

// 429 — rate limited
{"error": "Rate limited", "retry_after_seconds": 25, "camera": "pmn-camera-01-triggered"}

// 502 — MQTT publish failed
{"error": "Trigger delivery failed"}

// 503 — Event Grid not configured
{"error": "Event Grid not configured", "detail": "EVENT_GRID_HOSTNAME not set"}
```

**Example Request:**

```bash
curl -X POST "https://func-video-query-poc-001.azurewebsites.net/api/trigger?camera=pmn-camera-01-triggered&code=<KEY>"
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
   pip install -r requirements.txt
   ```

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
* `FFMPEG_PATH`: Path to ffmpeg binary (default: "ffmpeg", required only for stitch=true)
* `EVENT_GRID_HOSTNAME`: Event Grid Namespace MQTT hostname (required for trigger endpoint)
* `AZURE_CLIENT_ID`: Managed identity client ID for OAuth (default: "video-query-trigger")

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
     --storage-account edgeaistorage
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
       SAS_EXPIRY_HOURS="24" \
       FFMPEG_PATH="$HOME/bin/ffmpeg"
   ```

4. Install ffmpeg in the Function App:

   ```bash
   # Option 1: Run install script during deployment
   az functionapp deployment source config-zip \
     --name video-query-func \
     --resource-group rg-edge-ai \
     --src <path-to-zip-with-install-script>

   # The install-ffmpeg.sh script will run automatically

   # Option 2: Use custom container with ffmpeg pre-installed
   # See docs/custom-container-deployment.md for details
   ```

5. Deploy the function:

   ```bash
   func azure functionapp publish video-query-func
   ```

6. (Optional) Test stitching functionality:

   ```bash
   func azure functionapp publish video-query-func

   # Test without stitching (fast)
   curl "https://video-query-func.azurewebsites.net/api/video?camera=reolink-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z"

   # Test with stitching (requires ffmpeg)
   curl "https://video-query-func.azurewebsites.net/api/video?camera=reolink-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true"
   ```

## Performance

* **Query Time**: < 1 second for queries up to 1 hour
* **SAS Generation**: < 100ms per segment
* **Response Time (stitch=false)**: < 2 seconds for typical queries (up to 100 segments)
* **Response Time (stitch=true)**: 2-10 seconds depending on segment count and duration
* **Stitching Time**: ~500ms for 30-minute video (no re-encoding)
* **Storage Efficiency**: Hierarchical blob paths enable optimal distribution

## Query Optimization

The API automatically selects the optimal query strategy based on duration:

* **< 1 hour**: Prefix-based list queries
  * Fastest method for short timeframes
  * Uses hierarchical path structure
  * Example: `{camera_id}/{YYYY}/{MM}/{DD}/{HH}/`

* **1-24 hours**: Blob index tag queries
  * Efficient for longer timeframes
  * Filters by `camera_id`, `start_time`, `end_time` tags
  * Avoids full container scans

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
curl "https://func.azurewebsites.net/api/video?camera=reolink-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z"
```

**Response:** Array of segment URLs with metadata

**Client-side concatenation (if needed):**

```bash
# Download segments
for url in $(cat response.json | jq -r '.segments[].url'); do
  wget "$url"
done

# Concatenate with ffmpeg
ffmpeg -f concat -safe 0 -i filelist.txt -c copy merged.mp4
```

### Use stitch=true

**Best for:**

* Single video file output
* Users without ffmpeg/technical tools
* Direct playback in simple video players
* Simplified downstream processing

**Requirements:**

* FFmpeg installed in Function App environment
* `temp-videos` container for temporary storage
* Slower response time (2-10 seconds)

**Example:**

```bash
curl "https://func.azurewebsites.net/api/video?camera=reolink-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z&stitch=true"
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

* **Function Execution**: Consumption plan charges per execution (minimal, < 1 second)
* **Storage**: Cool tier recommended for segments older than 30 days
* **Egress**: SAS URLs enable direct client downloads (no Function egress)
* **No Temporary Storage**: API returns direct segment URLs

## Security

* Function-level authentication required by default
* SAS URLs use read-only permissions
* Temporary videos expire after 24 hours
* Connection strings stored in Key Vault (recommended)

## Contributing

Follow repository contribution guidelines when modifying this component.

## Related Components

* **503-media-capture-service**: Continuous recording service that produces segments
* **920-video-query-sdk**: Python SDK for data scientists (needs updating for new response format)

## Recent Changes

### March 2026 - Trigger Endpoint and Error Sanitization

**New Endpoint**: `POST /api/trigger` — on-demand video capture via Event Grid MQTT.

* Publishes `ALERT_DLQC` events to Event Grid Namespace (MQTTv5, TLS, port 8883)
* OAuth authentication via managed identity
* 30-second per-camera rate limiting
* Returns 202 Accepted with `event_id` and `estimated_ready_seconds`

**Security Hardening**: Error responses no longer expose internal details.

* 500 returns `{"error": "Internal server error"}` (no stack trace or exception details)
* 502 returns `{"error": "Trigger delivery failed"}` (no MQTT internals)
* MQTT client uses `try/finally` for reliable `loop_stop()`/`disconnect()` cleanup

### February 2026 - JSON Metadata Enrichment

**Enhancement**: API now reads companion JSON metadata files to enrich segment responses.

**New response fields** (when metadata available):

* `duration_seconds`: Exact segment duration from recorder
* `location`: Camera location/UNS hierarchy
* `segment_start`: Precise start timestamp with nanoseconds
* `segment_end`: Precise end timestamp with nanoseconds

**Example enriched response:**

```json
{
  "segments": [{
    "url": "https://...",
    "name": "camera-01/2026/02/04/18/segment_xxx.mp4",
    "timestamp": "2026-02-04T18:49:42+00:00",
    "size_bytes": 133169152,
    "recording_type": "continuous",
    "event_type": null,
    "duration_seconds": 300,
    "location": "PMN-Plant",
    "segment_start": "2026-02-04T18:49:42.452942021+00:00",
    "segment_end": "2026-02-04T18:54:42.452942021+00:00"
  }]
}
```

**Note**: Metadata fields are populated from sidecar `.json` files produced by the media capture service. Fields will be `null` if metadata is unavailable.

### February 2026 - Enhanced Stitching with Metadata

**Enhancement**: Server-side stitching now leverages JSON metadata for improved accuracy.

**Improvements:**

* **Precise segment ordering**: Segments sorted by `segment_start` metadata timestamps instead of filename parsing
* **Gap detection**: Identifies and reports gaps > 5 seconds between consecutive segments
* **Actual duration**: Reports `actual_duration_seconds` summed from metadata (vs. `query_duration_seconds` from request)
* **Location tracking**: Reports unique locations across stitched segments
* **Metadata coverage**: Indicates percentage of segments with available metadata

**New stitch response fields:**

* `actual_duration_seconds`: Total duration from summed segment metadata
* `earliest_segment_start`: Precise timestamp of first segment start
* `latest_segment_end`: Precise timestamp of last segment end
* `locations`: Array of unique locations in the stitched video
* `metadata_coverage`: Percentage of segments with JSON metadata (0-100)
* `gaps`: Array of detected gaps with timing details (when present)
* `gap_count`: Number of gaps detected
* `total_gap_seconds`: Sum of all gap durations

### January 2026 - Empty Results Response Fix

**Bug Fix**: Empty query results now correctly return HTTP 200 instead of HTTP 404.

**Previous behavior**: Queries with no matching segments returned 404 Not Found
**New behavior**: Queries with no matching segments return 200 OK with empty segments array

**Response format:**

```json
{
  "segments": [],
  "total_segments": 0,
  "message": "No video segments found for camera '...' between ... and ..."
}
```

**Rationale**: HTTP 404 implies the API endpoint doesn't exist, which is incorrect. Empty results are a valid response to a valid query.

### January 2026 - Optional Server-Side Stitching

**Enhancement**: Added optional `stitch=true` parameter for server-side video concatenation.

**Default behavior (stitch=false)**: Returns array of individual segment URLs (fast, flexible)
**Optional behavior (stitch=true)**: Returns single merged video URL (user-friendly, requires ffmpeg)

**Use cases:**

* **stitch=false**: Data scientists, programmatic access, parallel downloads, fast response
* **stitch=true**: Business users, simple playback, no local tools required

### January 2026 - API Response Format Update

**Breaking Change**: The API now returns an array of individual segment URLs by default instead of a single merged video URL.

**Reason**: Removed mandatory server-side video concatenation to simplify deployment and improve response times. Stitching is now optional.

**Migration Guide**:

* Old response: `{"video_url": "...", "duration": 1800, "segments": 6}`
* New response: `{"segments": [{"url": "...", "name": "...", "timestamp": "...", "size_bytes": 36175872}], "total_segments": 1}`
* Clients should iterate through `segments` array and download each URL
* Video players that support playlists (e.g., VLC, ffmpeg concat) can play segments sequentially
* Client-side concatenation example:

  ```bash
  # Download all segments
  for url in $(cat segments.json | jq -r '.segments[].url'); do
    wget "$url"
  done

  # Concatenate with ffmpeg (if needed)
  ffmpeg -f concat -safe 0 -i filelist.txt -c copy merged.mp4
  ```

**Components Requiring Updates**:

* `920-video-query-sdk`: Python SDK client wrapper needs to handle new response format
* Jupyter notebooks using the SDK need response format updates
