# Component Integration Flow Diagram

This diagram shows how all system components integrate together, illustrating the continuous recording flow, on-demand query capabilities, and data scientist analysis workflow.

## System Components

### Edge Environment

#### 📹 ONVIF Camera (camera-01)

- **Purpose**: Video source providing continuous RTSP stream
- **Protocol**: RTSP (Real-Time Streaming Protocol)
- **Output**: H.264 video at 1920x1080, 30fps
- **Component**: Physical camera device

#### 🔧 Device Registry (111-assets)

- **Purpose**: Camera configuration and metadata management
- **Function**: Stores camera URLs, credentials, and streaming settings
- **Component**: Azure IoT Operations asset management

#### 🎬 Media Capture Service (503-media-capture-service)

- **Purpose**: Continuous video recording with segmentation and local retention management
- **Functions**:
  - Captures RTSP streams from cameras
  - Segments video into 5-minute MP4 files
  - Writes segments to ACSA volume
  - Automatic cleanup of old local files (configurable retention period)
  - Subscribes to MQTT query requests
  - Publishes query responses
- **Component**: Custom Rust application running in Kubernetes

#### 📨 MQTT Broker

- **Purpose**: Message hub for edge communication
- **Functions**: Real-time query request/response messaging
- **Component**: Azure IoT Operations MQTT broker

#### 💾 ACSA Volume

- **Purpose**: Edge-to-cloud storage synchronization
- **Path**: `/cloud-sync/video-recordings/`
- **Functions**:
  - Local storage for video segments (with automatic retention cleanup)
  - Automatic background sync to Azure Blob Storage
  - Offline buffering during network outages
  - Retry logic for failed uploads
- **Component**: Azure Container Storage enabled by Arc

### Azure Cloud

#### ☁️ Blob Storage

- **Purpose**: Centralized video segment storage with lifecycle management
- **Features**:
  - Multi-tier storage (Hot/Cool/Archive)
  - Automatic tier transitions based on age
  - Blob index for efficient querying
  - 91% cost reduction over one year
- **Component**: Azure Storage Account

#### ⚡ Video Query API (520-video-query-api)

- **Purpose**: Historical video query and stitching service
- **Functions**:
  - Query blob storage by time range
  - Download video segments
  - Stitch segments with FFmpeg
  - Return single continuous video file
- **Component**: Azure Function (Python)

### Data Scientist Workstation

#### 🐍 Python SDK (920-video-query-sdk)

- **Purpose**: Developer interface for video queries
- **Functions**:
  - Submit queries via MQTT (real-time) or REST (historical)
  - Handle SAS URL generation
  - Provide simple Python API
- **Component**: Python library

#### 📊 Jupyter Notebook

- **Purpose**: Video analysis and visualization
- **Functions**: Load videos, perform CV analysis, visualize results
- **Component**: Data science environment

## Data Flow Steps

### Continuous Recording Flow

### Step 1: Video Streaming

- Camera streams RTSP video continuously to Media Capture Service
- Connection maintained 24/7 with automatic reconnection

### Step 2: Write to ACSA

- Media Capture Service writes MP4 segments to ACSA volume
- Each segment is 5 minutes duration
- Companion JSON metadata file created for each segment

### Step 3: Auto-Sync to Cloud

- ACSA automatically syncs files to Azure Blob Storage
- Sync happens in background (typically within 1-2 minutes)
- Handles network failures with retry logic
- No application code needed for sync

### Step 4: Lifecycle Management

- Blob Storage automatically moves files between tiers:
  - Days 0-7: Hot tier (immediate access)
  - Days 7-30: Cool tier (lower cost)
  - Days 30-365: Archive tier (lowest cost)
  - After 365 days: Automatic deletion

### Step 5: Local Retention Cleanup

- Media Capture Service runs background cleanup task (default: hourly)
- Deletes local segments older than retention period (default: 24 hours)
- Removes empty timestamp directories after cleanup
- Prevents disk space exhaustion on edge nodes
- Cloud-synced files remain available in Blob Storage

### On-Demand Query Flow (MQTT Path)

### Step 6: Query Request

- Data Scientist uses Python SDK to submit query
- Example: `get_video("camera-01", "2026-01-20T10:00:00Z", "2026-01-20T10:30:00Z")`

### Step 7: Publish to MQTT

- SDK publishes query request to MQTT broker
- Topic: `video/query/request`
- Payload includes camera ID, start time, end time

### Step 8: Media Capture Receives Request

- Media Capture Service subscribed to request topic
- Validates time range
- Checks if segments exist locally or in cloud

### Step 9: Generate URLs

- Creates SAS (Shared Access Signature) URLs for each segment
- URLs provide temporary access (1 hour validity)
- Returns list of segment URLs

### Step 10: Response via MQTT

- Publishes response to `video/query/response` topic
- SDK receives list of blob URLs
- Data Scientist downloads segments directly from Blob Storage

### On-Demand Query Flow (REST API Path)

### Step 11: Query via REST API

- Alternative to MQTT: HTTP POST to Video Query API
- Used when MQTT connectivity not available or stitched video preferred

### Step 12: API Processing

- Query Blob Storage for matching segments
- Download all segments
- Stitch together using FFmpeg
- Upload stitched video to temporary blob

### Step 13: Return Stitched Video

- Returns single SAS URL to stitched video
- Data Scientist downloads one continuous video file
- Simplifies analysis compared to multiple segments

### Analysis Flow

### Step 13: Video Analysis

- Data Scientist loads video in Jupyter
- Performs computer vision analysis:
  - Object detection
  - Motion tracking
  - Event detection
  - Quality metrics

## Component Interactions

### Media Capture Service Interactions

- **Inbound**:
  - RTSP video from cameras (continuous)
  - MQTT query requests (on-demand)
  - Configuration from Device Registry (startup)
- **Outbound**:
  - Video segments to ACSA volume (every 5 minutes)
  - MQTT query responses (on-demand)
  - Status updates to MQTT (periodic)

### ACSA Volume Interactions

- **Inbound**:
  - Video segments from Media Capture Service
  - Metadata JSON files
- **Outbound**:
  - Automatic sync to Blob Storage (background)
  - Retry on failures

### Video Query API Interactions

- **Inbound**:
  - HTTP query requests from SDK
- **Outbound**:
  - Blob storage queries (Blob Index)
  - Segment downloads
  - Stitched video uploads
  - SAS URL responses

### Python SDK Interactions

- **MQTT Mode**:
  - Publish to MQTT broker (request)
  - Subscribe to MQTT broker (response)
  - Direct downloads from Blob Storage URLs
- **REST Mode**:
  - HTTP POST to Video Query API
  - Download stitched video from returned URL

## Key Architecture Points

### 1. ACSA Centrality

- **No custom sync code**: Application just writes to local volume
- **Automatic resilience**: Built-in retry and offline buffering
- **Transparent operation**: Apps don't know they're writing to cloud storage
- **Optimized sync**: Batching and compression handled automatically

### 2. MQTT as Edge Hub

- **Low latency**: Sub-second query response times
- **Pub/sub pattern**: Loose coupling between components
- **Local communication**: All edge traffic stays on-premises
- **Standardized protocol**: Easy integration with other systems

### 3. Dual Query Paths

- **MQTT**: Fast, returns multiple segments, requires edge connectivity
- **REST API**: Slower, returns stitched video, works from anywhere
- **Choice**: Data Scientist picks based on use case

### 4. Component Modularity

- **111-assets**: Camera management can be updated independently
- **503-media-capture-service**: Recording logic isolated
- **520-video-query-api**: Query/stitching can scale separately
- **920-video-query-sdk**: Client library versioned independently
