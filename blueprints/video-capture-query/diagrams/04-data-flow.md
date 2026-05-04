# Data Flow Diagram

This diagram provides a detailed 14-step walkthrough of how data flows through the entire system, from query request to analysis.

## Complete Data Flow (14 Steps)

### Phase 1: Continuous Recording (Steps 1-5)

#### Step 1: Video Streaming

- **Source**: ONVIF Camera (camera-01)
- **Protocol**: RTSP stream
- **Target**: Media Capture Service
- **Details**: Continuous H.264 video stream at 1920x1080, 30fps

#### Step 2: Video Recording

- **Component**: Media Capture Service (503-media-capture-service)
- **Process**:
  - Captures RTSP stream
  - Segments video into 5-minute chunks
  - Generates MP4 files with H.264 codec
- **Output**: video-2026-01-20T10-00-00Z.mp4 (and subsequent segments)

#### Step 3: Write to ACSA Volume

- **Component**: ACSA Writer module
- **Process**:
  - Writes MP4 file to `/cloud-sync/video-recordings/` volume
  - Creates companion JSON metadata file
  - Organizes with hierarchical timestamp paths
- **Files Created**:
  - `camera-01/2026/01/20/10/segment_2026-01-20T10:00:00Z_camera-01.mp4`
  - `camera-01/2026/01/20/10/segment_2026-01-20T10:00:00Z_camera-01.json`

#### Step 4: ACSA Auto-Sync

- **Component**: Azure Container Storage enabled by Arc (ACSA)
- **Process**:
  - Monitors ACSA volume for new files
  - Automatically uploads to Azure Blob Storage
  - Handles network failures with retry logic
  - Maintains offline buffer during connectivity issues
- **Target**: Hot tier in Blob Storage

#### Step 5: Local Retention Cleanup

- **Component**: Media Capture Service (background task)
- **Process**:
  - Runs cleanup task at configured interval (default: hourly)
  - Deletes local files older than retention period (default: 24 hours)
  - Recursively removes empty timestamp directories
  - Prevents disk space exhaustion on edge nodes
- **Note**: Cloud-synced files remain available in Blob Storage

### Phase 2: Real-Time Query Request (Steps 6-10)

#### Step 6: Query Request via SDK

- **Actor**: Data Scientist
- **Component**: Python SDK (920-video-query-sdk)
- **Request**: `get_video("camera-01", "2026-01-20T10:00:00Z", "2026-01-20T10:30:00Z")`
- **Method**: MQTT-based query for real-time response

#### Step 7: Publish to MQTT Broker

- **Component**: Python SDK
- **Protocol**: MQTT over Azure IoT Operations
- **Topic**: `video/query/request`
- **Payload**:

```json
{
  "request_id": "uuid-1234",
  "camera_id": "camera-01",
  "start_time": "2026-01-20T10:00:00Z",
  "end_time": "2026-01-20T10:30:00Z"
}
```

#### Step 8: Media Capture Service Receives Request

- **Component**: Media Capture Service
- **Process**:
  - Subscribed to `video/query/request` topic
  - Receives query request
  - Validates time range (30 minutes = 6 segments)
  - Checks if segments exist in ACSA volume or cloud

#### Step 9: Generate Blob URLs

- **Component**: Media Capture Service
- **Process**:
  - Generates SAS (Shared Access Signature) URLs for each segment
  - Creates temporary access tokens (valid for 1 hour)
  - Lists required segments (6 MP4 files)

#### Step 10: Publish Response to MQTT

- **Component**: Media Capture Service
- **Protocol**: MQTT response
- **Topic**: `video/query/response`
- **Payload**:

```json
{
  "request_id": "uuid-1234",
  "status": "success",
  "segments": [
    "https://storage.../a1/camera-01/.../video-2026-01-20T10-00-00Z.mp4?sas=...",
    "https://storage.../a1/camera-01/.../video-2026-01-20T10-05-00Z.mp4?sas=...",
    "...6 segments total..."
  ]
}
```

### Phase 3: Historical Query (Steps 11-13)

**Note**: This is an alternative path when real-time MQTT query is not needed.

#### Step 11: Query via REST API

- **Actor**: Data Scientist
- **Component**: Python SDK
- **Target**: Video Query API (520-video-query-api)
- **Request**:
  - `POST /api/query-video`
  - Body: `{"camera_id": "camera-01", "start": "2026-01-20T10:00:00Z", "end": "2026-01-20T10:30:00Z"}`

#### Step 12: Video Query API Processing

- **Component**: Azure Function (Video Query API)
- **Process**:
  1. **Query Blob Index**: Find relevant segments using tags
  2. **Download Segments**: Retrieve 6 MP4 files from Blob Storage
  3. **Stitch with FFmpeg**: Concatenate segments into single video
  4. **Upload Result**: Save stitched video to temporary blob
  5. **Generate SAS URL**: Create 24-hour access token

#### Step 13: Return Stitched Video

- **Component**: Video Query API
- **Response**:

```json
{
  "status": "success",
  "video_url": "https://storage.../stitched/camera-01-2026-01-20-10-00.mp4?sas=...",
  "duration_seconds": 1800,
  "size_bytes": 180000000
}
```

### Phase 4: Analysis (Step 14)

#### Step 14: Video Analysis

- **Component**: Jupyter Notebook / Python Analysis Tools
- **Process**:
  - Downloads video from SAS URL
  - Loads into analysis frameworks (OpenCV, PyTorch, etc.)
  - Performs computer vision tasks:
    - Object detection
    - Motion tracking
    - Event detection
    - Quality analysis

## Query Path Comparison

### MQTT Path (Steps 5-9)

- **Pros**: Real-time response, lightweight, no stitching overhead
- **Cons**: Requires MQTT connectivity, returns multiple segments
- **Use Case**: Fast queries, edge-connected applications, real-time monitoring

### REST API Path (Steps 10-12)

- **Pros**: Single stitched video, standard HTTP, no edge connectivity needed
- **Cons**: Higher latency, processing overhead, more bandwidth
- **Use Case**: Historical analysis, offline queries, external systems

## Performance Characteristics

| Phase                      | Typical Duration | Bottleneck       |
|----------------------------|------------------|------------------|
| Continuous Recording (1-5) | Real-time        | Camera bandwidth |
| Real-Time Query (6-10)     | < 1 second       | MQTT round-trip  |
| Historical Query (11-13)   | 10-60 seconds    | FFmpeg stitching |
| Analysis (14)              | Varies           | Video processing |

## Error Handling

### Network Failures

- **Step 4 (ACSA Sync)**: Automatic retry with exponential backoff
- **Step 7 (MQTT)**: Connection loss detection and reconnection
- **Step 12 (Download)**: Segment-level retry logic

### Missing Data

- **Step 8**: Media Capture Service checks for gaps in recording
- **Step 12**: Video Query API handles missing segments gracefully
- **Response**: Returns partial results with gap indicators

### Archive Rehydration

- **Scenario**: Requesting video older than 30 days (in Archive tier)
- **Process**:
  1. API detects archive-tier blobs
  2. Initiates rehydration (1-15 hours)
  3. Returns 202 Accepted with estimated completion time
  4. Client polls for completion
