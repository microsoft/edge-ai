---
title: Continuous Video Capture with ACSA-Based Cloud Synchronization
description: Architecture Decision Record for implementing continuous video recording from ONVIF cameras with automatic edge-to-cloud synchronization using Azure Container Storage Accelerator (ACSA), enabling time-based video query capabilities for Data Scientists
author: Edge AI Team
ms.date: 2026-01-09
ms.topic: architecture-decision-record
estimated_reading_time: 15
keywords:
  - video-capture
  - continuous-recording
  - acsa
  - azure-iot-operations
  - onvif-cameras
  - edge-to-cloud-sync
  - blob-storage
  - lifecycle-management
  - video-query
  - time-based-retrieval
  - ffmpeg
  - rust
  - azure-functions
  - architecture-decision-record
  - adr
---

## Status

- [ ] Draft
- [x] Proposed
- [ ] Accepted
- [ ] Deprecated

**Date:** 2026-01-08
**Proposed:** 2026-01-09

## Context

### Business Need

Industrial and manufacturing environments require the ability to capture continuous video from surveillance cameras for compliance, quality assurance, incident investigation, and operational analysis. Data Scientists need programmatic access to retrieve historical video segments based on time ranges to perform:

- **Incident Investigation**: Retrieve video from specific time periods when events occurred
- **Quality Analysis**: Extract video segments for visual inspection and defect detection
- **Compliance Auditing**: Access historical footage for regulatory compliance verification
- **Operational Analytics**: Analyze video patterns across time periods for process optimization
- **AI Model Training**: Collect video data for training computer vision models

### Technical Requirements

The continuous video capture solution must meet the following requirements:

**Recording Requirements:**

- 24/7 continuous recording from ONVIF-compliant cameras
- RTSP stream ingestion with H.264 codec support
- Configurable segment duration (default 5 minutes) for manageable file sizes
- Support for multiple cameras with independent recording streams
- Automatic reconnection and error recovery for camera streams

**Storage Requirements:**

- Edge buffering to handle network disruptions to cloud
- Automatic synchronization to Azure Blob Storage
- Cost-optimized storage with lifecycle management (Hot → Cool → Archive → Delete)
- Efficient path organization for time-based queries (year/month/day/hour structure)
- Metadata files accompanying each video segment for quick filtering

**Query Requirements:**

- Time-based video retrieval (specify camera ID, start time, end time)
- Two query paths:
  - Real-time MQTT-based queries returning segment URLs (< 1 second response)
  - Historical REST API queries with FFmpeg-stitched continuous video (10-60 second response)
- Python SDK for Data Scientists to simplify video queries from Jupyter notebooks
- SAS token generation for secure, time-limited access to video segments

**Integration Requirements:**

- Integration with Azure IoT Operations for edge orchestration
- MQTT broker for real-time query/response messaging
- Azure Container Storage Accelerator (ACSA) for automatic cloud sync
- Support for existing edge infrastructure (K3s Kubernetes)
- Azure Functions for video query and stitching API

**Operational Requirements:**

- Minimal operational overhead (no custom upload code)
- Automatic retry and offline buffering during network failures
- Health monitoring and metrics exposure
- Configurable retention policies aligned with compliance requirements
- Container-based deployment for portability

### Existing Architecture Context

The video capture system operates within the Azure IoT Operations ecosystem:

- **MQTT Broker**: Azure IoT Operations MQTT broker for request/response messaging
- **Device Registry (111-assets)**: Camera asset management and configuration
- **ACSA**: Azure Container Storage Accelerator for edge-to-cloud synchronization
- **Edge Storage**: Local K3s persistent volumes for ACSA mount points
- **Cloud Storage**: Azure Blob Storage with multi-tier lifecycle policies
- **Observability**: Prometheus/Grafana for monitoring recording health

### Problem Statement

Data Scientists currently have no systematic way to retrieve historical video from edge cameras:

1. **No Continuous Recording**: Existing media capture service only supports event-triggered recording (alert-based snapshots)
2. **Manual Video Retrieval**: No programmatic interface for time-based video queries
3. **Cloud Upload Complexity**: No automated mechanism for edge-to-cloud video synchronization
4. **Storage Cost Concerns**: Lack of lifecycle management leads to expensive long-term storage
5. **Fragmented Segments**: No ability to stitch multiple 5-minute segments into continuous video

Early implementations explored several approaches:

1. **Direct Azure SDK Upload**: Custom Rust code using Azure Storage SDK
   - ❌ Requires extensive error handling for network failures
   - ❌ Manual retry logic and offline buffering
   - ❌ Additional code maintenance burden
   - ❌ Bypasses ACSA's purpose-built edge-to-cloud sync

2. **Blob Trigger Functions**: Azure Functions triggered by blob creation
   - ❌ Higher latency (5-15 seconds)
   - ❌ Cold start issues for consumption plan
   - ❌ Additional cost per blob operation

3. **Custom Sync Service**: Separate service monitoring local storage
   - ❌ Duplicate functionality with ACSA
   - ❌ Additional service to manage and monitor

## Decision

Implement a **Rust-based continuous video recorder** that writes to **ACSA-mounted volumes**, with **dual query paths** (MQTT for real-time, REST API for historical), and **FFmpeg-based video stitching** for continuous playback:

1. **Continuous Recording Engine**: Rust service capturing RTSP streams continuously
2. **ACSA-Based Sync**: Write MP4 segments + JSON metadata to ACSA volume; ACSA handles automatic cloud sync
3. **Time-Based Organization**: Hash-prefixed hierarchical paths (year/month/day/hour) for efficient queries
4. **Lifecycle Management**: Automated tier transitions (Hot → Cool → Archive → Delete) based on age
5. **Dual Query Architecture**:
   - **MQTT Path**: Real-time queries returning segment URLs (< 1s response)
   - **REST API Path**: Azure Function stitching segments into continuous video (10-60s response)
6. **Python SDK**: Simple interface for Data Scientists to query and download video

### Architecture Pattern: ACSA as the Sync Abstraction

Instead of implementing custom Azure Storage SDK code in the media capture service, we leverage **ACSA as the edge-to-cloud synchronization layer**:

```rust
// Simple write to ACSA volume - no Azure SDK code needed
pub struct AcsaWriter {
    acsa_mount_path: PathBuf,
}

impl AcsaWriter {
    pub async fn write_segment_with_metadata(
        &self,
        video_file: &Path,
        camera_id: &str,
        camera_location: &str,
        segment_start: DateTime<Utc>,
        segment_end: DateTime<Utc>,
    ) -> Result<(), Box<dyn Error>> {
        // Write MP4 file to ACSA volume
        let video_path = self.generate_acsa_path(camera_id, segment_start);
        fs::copy(video_file, &video_path).await?;

        // Write companion JSON metadata
        let metadata = json!({
            "camera_id": camera_id,
            "location": camera_location,
            "segment_start": segment_start.to_rfc3339(),
            "segment_end": segment_end.to_rfc3339(),
            "duration_seconds": (segment_end - segment_start).num_seconds(),
            "file_path": video_path.to_str(),
        });
        let metadata_path = video_path.with_extension("json");
        fs::write(&metadata_path, serde_json::to_string_pretty(&metadata)?).await?;

        // ACSA automatically syncs to Azure Blob Storage
        info!("ACSA will automatically sync {} to cloud", video_path.display());
        Ok(())
    }
}
```

**Rationale:**

- **Operational Simplicity**: No custom sync code, retry logic, or offline buffering
- **Built-in Reliability**: ACSA provides retry, offline buffer, and network failure handling
- **Azure IoT Operations Native**: ACSA is purpose-built for Azure IoT Operations edge-to-cloud scenarios
- **Reduced Maintenance**: No need to maintain Azure Storage SDK integration
- **Clear Separation**: Recording service focuses on video capture; ACSA handles sync

### Storage Organization Pattern: Hash-Prefixed Hierarchical Paths

Videos are organized using a two-level structure for optimal query performance:

```text
media-capture-data/
├── a1/                              # MD5 hash prefix (first 2 chars of camera ID hash)
│   └── camera-01/
│       └── 2026/01/09/10/
│           ├── video-2026-01-09T10-00-00Z.mp4
│           ├── video-2026-01-09T10-00-00Z.json
│           ├── video-2026-01-09T10-05-00Z.mp4
│           └── video-2026-01-09T10-05-00Z.json
└── b2/
    └── camera-02/
        └── ...
```

**Rationale:**

- **Load Balancing**: Hash prefixes distribute camera data across storage partitions
- **Time-Based Queries**: Year/month/day/hour structure enables fast prefix-based blob listing
- **Blob Index Tags**: Each video tagged with `camera_id`, `start_time`, `duration_seconds` for efficient filtering (future enhancement)
- **Metadata Co-location**: JSON files alongside MP4 files enable the Video Query API to enrich responses with precise timing and location data without parsing video files

### Dual Query Pattern: MQTT + REST API

Two query paths serve different use cases:

**MQTT Path (Real-Time)**:

```python
# Fast query returning segment URLs (< 1 second)
client = VideoClient(mqtt_broker="192.168.102.100:1883")
result = client.get_video_mqtt(
    camera_id="camera-01",
    start_time="2026-01-09T10:00:00Z",
    end_time="2026-01-09T10:30:00Z"
)
# Returns: List of segment URLs with SAS tokens
```

**REST API Path (Historical) - Default Mode**:

```python
# Fast query returning segment URLs (< 2 seconds)
result = client.get_video_api(
    camera_id="camera-01",
    start_time="2026-01-09T10:00:00Z",
    end_time="2026-01-09T10:30:00Z"
)
# Returns: List of segments with URLs, timestamps, and metadata
```

**REST API Path (Historical) - Stitched Mode**:

```python
# Slower query returning stitched video (2-10 seconds)
result = client.get_video_api(
    camera_id="camera-01",
    start_time="2026-01-09T10:00:00Z",
    end_time="2026-01-09T10:30:00Z",
    stitch=True
)
# Returns: Single continuous 30-minute MP4 URL
```

**Rationale:**

- **MQTT**: Low latency for real-time queries, returns multiple segments
- **REST API (default)**: Fast response with segment array, flexible for programmatic access
- **REST API (stitch=true)**: Higher latency but returns continuous video (FFmpeg-stitched), user-friendly
- **Use Case Alignment**: MQTT for responsive UIs, REST API default for data science, REST API stitched for business users
- **Flexibility**: Data Scientists choose based on their workflow needs

## Decision Drivers

### Primary Drivers (High Priority)

1. **ACSA Alignment**
   - **Description**: Leverage Azure IoT Operations' purpose-built edge-to-cloud sync
   - **Impact**: Eliminates 400+ lines of custom Azure SDK code, automatic retry/buffer
   - **Weight**: Critical - reduces maintenance burden and aligns with Azure IoT Ops architecture

2. **Cost Optimization**
   - **Description**: Multi-tier storage with lifecycle policies
   - **Impact**: 91% cost reduction (Hot $657/month → Mixed $58/month for 100GB/day/camera)
   - **Weight**: Critical - enables long-term retention without prohibitive costs

3. **Data Scientist Accessibility**
   - **Description**: Simple Python SDK for video queries from Jupyter notebooks
   - **Impact**: Reduces video retrieval from hours (manual) to minutes (programmatic)
   - **Weight**: High - directly impacts data scientist productivity

4. **Query Performance**
   - **Description**: Dual query paths optimized for different use cases
   - **Impact**: MQTT < 1s for quick checks, REST API 10-60s for continuous video
   - **Weight**: High - affects user experience for different workflows

### Secondary Drivers (Medium Priority)

1. **Operational Simplicity**
   - **Description**: Single Rust service, Helm chart deployment, minimal configuration
   - **Impact**: Reduces operational complexity and deployment time
   - **Weight**: Medium - improves maintainability

2. **Metadata Co-location**
   - **Description**: JSON files alongside MP4 for quick attribute queries
   - **Impact**: Enables filtering without video parsing
   - **Weight**: Medium - improves query efficiency

## Considered Options

### Option 1: ACSA-Based Sync with Rust Recorder (Selected)

**Description**: Rust service writes MP4 + JSON to ACSA volume; ACSA handles cloud sync automatically.

**Technical Details**:

- Rust continuous recorder using FFmpeg
- ACSA PersistentVolume mounted at `/cloud-sync/video-recordings`
- Write-only interface (no Azure SDK code)
- Dual query: MQTT (real-time) + Azure Function (historical stitching)

**Pros**:

- ✅ No custom sync code (ACSA handles everything)
- ✅ Built-in retry logic and offline buffering
- ✅ Aligns with Azure IoT Operations architecture
- ✅ Reduced maintenance burden (no Azure SDK updates)
- ✅ Rust performance for recording (< 100MB container, 2-3s cold start)
- ✅ Dual query paths serve different use cases

**Cons**:

- ⚠️ Requires ACSA configuration (PersistentVolume setup)
- ⚠️ ACSA sync lag (1-2 minutes typical, but acceptable for historical queries)
- ⚠️ Requires Rust expertise for recorder maintenance

**Risks**:

- **Risk**: ACSA connectivity issues causing data loss
  - **Probability**: Low (ACSA has offline buffering)
  - **Impact**: Medium (delayed cloud availability, but data not lost)
  - **Mitigation**: Monitor ACSA sync lag; alert if > 10 minutes; local volume size sufficient for 24hr buffer

- **Risk**: FFmpeg stitching performance degradation for long time ranges
  - **Probability**: Medium (large queries could be slow)
  - **Impact**: Low (REST API query path, not real-time)
  - **Mitigation**: Limit query range (max 2 hours), implement pagination, use MQTT path for quick queries

**Dependencies**:

- Azure IoT Operations with ACSA enabled
- K3s cluster with persistent volume support
- Azure Blob Storage account
- Azure Functions for video query API

**Costs**:

- **Initial**: ~40 hours development (Rust recorder + ACSA integration + Azure Function)
- **Ongoing**: Storage costs (Hot $18/TB/month, Cool $10, Archive $1.50)
- **Effort**: Low maintenance (ACSA handles sync, lifecycle policies automated)

### Option 2: Custom Azure SDK Upload in Rust

**Description**: Rust service uses Azure Storage SDK directly to upload segments to Blob Storage.

**Technical Details**:

- Azure Storage SDK Rust crate for blob uploads
- Custom retry logic and error handling
- Offline buffering with local queue
- Same dual query architecture

**Pros**:

- ✅ No ACSA dependency
- ✅ Direct control over upload process
- ✅ Potentially lower sync latency

**Cons**:

- ❌ 400+ lines of custom sync code
- ❌ Manual retry logic and exponential backoff
- ❌ Manual offline buffering implementation
- ❌ Azure SDK updates require maintenance
- ❌ Bypasses ACSA's purpose-built sync
- ❌ More complex error handling

**Risks**:

- **Risk**: Network failure handling complexity
  - **Probability**: High (edge environments have intermittent connectivity)
  - **Impact**: High (could lose video data)
  - **Mitigation**: Implement robust offline buffer, but this adds significant code

- **Risk**: Azure SDK breaking changes
  - **Probability**: Medium (SDK evolves over time)
  - **Impact**: Medium (requires maintenance and testing)
  - **Mitigation**: Pin SDK versions, but delays security updates

**Dependencies**:

- Azure Storage SDK for Rust
- Local persistent volume for offline buffer
- Azure Blob Storage account

**Costs**:

- **Initial**: ~60 hours development (SDK integration + retry logic + offline buffer)
- **Ongoing**: Same storage costs as Option 1
- **Effort**: High maintenance (SDK updates, bug fixes in sync logic)

**Why Not Chosen**: Bypasses ACSA's purpose-built functionality, significantly higher development and maintenance cost.

### Option 3: Python-Based Recorder with OpenCV

**Description**: Python service using OpenCV for RTSP capture, Azure SDK for upload.

**Technical Details**:

- Python with OpenCV for video capture
- Azure Storage SDK for Python
- Similar architecture to Option 2

**Pros**:

- ✅ More Python developers available
- ✅ Rich ecosystem for video processing

**Cons**:

- ❌ Higher memory footprint (1.2GB+ container vs 100MB Rust)
- ❌ Slower cold start (6-8 seconds vs 2-3 seconds)
- ❌ Lower throughput per CPU core
- ❌ Still requires custom sync code (same as Option 2)

**Risks**:

- **Risk**: Resource constraints on edge devices
  - **Probability**: High (multiple camera streams)
  - **Impact**: High (container OOM kills)
  - **Mitigation**: Limit cameras per instance, but increases deployment complexity

**Dependencies**:

- Python runtime, OpenCV, Azure SDK
- Larger container images (> 500MB)

**Costs**:

- **Initial**: ~50 hours development
- **Ongoing**: Higher compute costs due to resource usage
- **Effort**: Medium-high maintenance

**Why Not Chosen**: Resource footprint too high for edge deployment, especially with multiple camera streams.

## Comparison Matrix

| Criteria                   | Weight   | Option 1: ACSA-Based (Selected) | Option 2: Custom SDK    | Option 3: Python        |
|----------------------------|----------|---------------------------------|-------------------------|-------------------------|
| **Development Effort**     | High     | 40 hours                        | 60 hours                | 50 hours                |
| **Maintenance Burden**     | High     | Low (ACSA handles sync)         | High (custom sync code) | Medium-High             |
| **Resource Efficiency**    | High     | Excellent (<100MB, low CPU)     | Good                    | Poor (1.2GB+, high CPU) |
| **Sync Reliability**       | Critical | Excellent (ACSA built-in)       | Manual implementation   | Manual implementation   |
| **Architecture Alignment** | High     | Perfect (Azure IoT Ops native)  | Bypasses ACSA           | Bypasses ACSA           |
| **Offline Resilience**     | High     | Excellent (ACSA buffer)         | Manual implementation   | Manual implementation   |
| **Query Performance**      | Medium   | MQTT < 1s, API 10-60s           | Same                    | Same                    |
| **Cost Optimization**      | High     | 91% reduction (lifecycle)       | Same                    | Higher (compute)        |
| **Developer Availability** | Medium   | Rust (moderate)                 | Rust (moderate)         | Python (high)           |

**Recommended**: Option 1 (ACSA-Based) is expected to excel in maintenance burden, sync reliability, architecture alignment, and offline resilience.

## Consequences

### Positive

- **Reduced Maintenance**: Will eliminate 400+ lines of custom sync code; ACSA will handle retry, buffering, network failures
- **Cost Optimization**: Projects 91% storage cost reduction through lifecycle policies ($657/month → $58/month for 100GB/day)
- **Data Scientist Productivity**: Python SDK will reduce video retrieval from hours (manual) to minutes (programmatic)
- **Architectural Alignment**: Will leverage Azure IoT Operations ACSA as designed
- **Operational Simplicity**: Single Rust service with Helm chart deployment
- **Query Flexibility**: Dual paths (MQTT + REST API) will serve different use cases
- **Offline Resilience**: ACSA's offline buffer will prevent data loss during connectivity issues

### Negative

- **ACSA Dependency**: Will require ACSA configuration and monitoring
- **Sync Latency**: Expected 1-2 minute lag to cloud (acceptable for historical queries, not real-time)
- **Rust Expertise**: Will require Rust developers for recorder maintenance
- **FFmpeg Complexity**: Video stitching will add Azure Function dependency

### Neutral

- **Dual Query Paths**: Will add complexity but serve different use cases
- **Metadata Files**: JSON co-location adds minimal storage overhead (~300 bytes per segment) but enables the Video Query API to return enriched responses with precise timestamps, duration, and location data without parsing video files
- **Hash Prefixing**: Will add path complexity but optimize load distribution

### Risks and Monitoring

**Ongoing Risks**:

- **ACSA Sync Lag**: Monitor sync lag; alert if > 10 minutes
- **Storage Capacity**: Monitor ACSA volume usage; ensure sufficient capacity for 24hr buffer
- **FFmpeg Performance**: Monitor stitching times; implement query range limits if needed
- **Camera Connectivity**: Monitor stream health; auto-reconnect on failures

**Target Success Metrics**:

- ACSA sync lag: < 2 minutes (p95)
- MQTT query response: < 1 second
- REST API query response: < 60 seconds for 30-minute videos
- Recording uptime: > 99.5% per camera
- Storage cost: < $60/month per camera (100GB/day)

## Implementation

### Phase 1: Core Recording and ACSA Sync (Week 1-2)

**Tasks**:

1. Implement Rust continuous recorder with FFmpeg
2. Configure ACSA PersistentVolume with Azure Blob Storage binding
3. Implement continuous recording with configurable segment duration
4. Create video segments with hierarchical timestamp paths
5. Test ACSA sync with network failure scenarios

**Deliverables**:

- Rust continuous recorder service
- ACSA PersistentVolume configuration
- Hierarchical path structure (year/month/day/hour)
- Network failure test results

### Phase 2: Blob Storage and Lifecycle Management (Week 2)

**Tasks**:

1. Configure blob index tags for efficient queries
2. Implement lifecycle management policies (Hot/Cool/Archive/Delete)
3. Create storage account with multi-tier configuration
4. Test tier transitions and access patterns

**Deliverables**:

- Blob Storage account with lifecycle policies
- Blob index tag schema
- Tier transition test results

### Phase 3: MQTT Query Path (Week 3)

**Tasks**:

1. Implement MQTT request/response handlers in recorder
2. Generate SAS tokens for segment URLs
3. Test MQTT query performance and reliability

**Deliverables**:

- MQTT query implementation
- SAS token generation
- Query performance benchmarks (< 1s response)

### Phase 4: REST API Query Path (Week 3-4)

**Tasks**:

1. Develop Azure Function for video query API
2. Implement FFmpeg-based video stitching
3. Create temporary blob storage for stitched videos
4. Generate SAS URLs for stitched video access

**Deliverables**:

- Azure Function deployment
- FFmpeg stitching logic
- Stitched video SAS generation
- Query performance benchmarks (10-60s response)

### Phase 5: Python SDK and Documentation (Week 4)

**Tasks**:

1. Develop Python SDK with simple query interface
2. Create Jupyter notebook examples
3. Write deployment documentation
4. Create architecture diagrams

**Deliverables**:

- Python SDK package
- Jupyter notebook examples
- Deployment guide
- Architecture diagrams (6 draw.io + markdown docs)

### Phase 6: Local File Retention Management (Post-Deployment Enhancement)

**Tasks**:

1. Implement configurable local file retention with automatic cleanup
2. Add background cleanup task with configurable interval
3. Implement recursive directory traversal for old file deletion
4. Remove empty directories after file cleanup
5. Make retention parameters configurable via Helm values

**Deliverables**:

- Background cleanup task using tokio interval timer
- Configurable `localRetentionHours` parameter (default: 24 hours)
- Configurable `cleanupIntervalMinutes` parameter (default: 60 minutes)
- Recursive async cleanup with Send-safe futures for tokio compatibility
- Automatic empty directory removal to prevent path accumulation
- Updated Helm chart with retention configuration options

**Implementation Details**:

- Cleanup task spawned on service startup, runs independently from recording loop
- Calculates cutoff time based on current timestamp minus retention hours
- Recursively traverses `/cloud-sync/video-recordings/{camera_id}/` directory structure
- Deletes MP4 files with modification time older than cutoff
- Removes empty year/month/day/hour directories after file deletion
- Uses idempotent directory creation (`create_dir_all`) to prevent race conditions
- Logs cleanup operations for observability (files deleted, directories removed)

**Configuration Example**:

```bash
helm install media-capture ./charts/media-capture-service \
  --set mediaCapture.continuousRecording.segmentDurationSeconds=300 \
  --set mediaCapture.continuousRecording.localRetentionHours=24 \
  --set mediaCapture.continuousRecording.cleanupIntervalMinutes=60
```

**Rationale**:

- Prevents disk space exhaustion on edge nodes with limited storage
- Maintains buffer for network interruptions (ACSA handles cloud sync)
- Reduces Azure egress costs by limiting local storage footprint
- Configurable to accommodate different customer storage constraints
- ACSA syncs files to cloud before local retention period expires

### Timeline

- **Total Duration**: 4 weeks
- **Team**: 2 developers (1 Rust, 1 Python/Azure Functions)
- **Deployment Target**: Production-ready by end of Week 4
- **Phase 6 Enhancement**: 2 days (post-deployment operational improvement)

### Resources Required

- **Development**: 2 developers (160 hours total)
- **Infrastructure**: Azure subscription with IoT Operations, Blob Storage, Functions
- **Edge Hardware**: K3s cluster with ACSA support
- **Testing**: ONVIF camera (real or simulated), network failure testing tools

## Future Considerations

### Monitoring Requirements

- **ACSA Sync Health**: Monitor sync lag, offline buffer size, failed uploads
- **Recording Health**: Monitor camera connectivity, stream errors, disk usage
- **Local Retention Cleanup**: Monitor cleanup task execution, files deleted, disk space freed, empty directories removed
- **Query Performance**: Monitor MQTT response times, API latency, FFmpeg stitching duration
- **Storage Costs**: Track blob tier distribution, lifecycle policy effectiveness
- **Alert Thresholds**: Sync lag > 10 min, recording uptime < 99.5%, query timeout > 60s, disk usage > 80%

### Evolution Opportunities

- **Multi-Camera Aggregation**: Support queries across multiple cameras
- **Video Analytics Integration**: Add AI-based event detection and indexing
- **Archive Rehydration**: Implement automatic rehydration for Archive tier queries
- **Blob Index Optimization**: Explore additional tags for advanced filtering
- **Edge Caching**: Implement local cache for frequently accessed segments
- **Compression Optimization**: Evaluate H.265 codec for storage savings

### Triggers for Review

- **ACSA Performance Issues**: If sync lag consistently exceeds SLA (> 10 minutes)
- **Storage Cost Overruns**: If lifecycle policies don't achieve target cost savings
- **Query Performance Degradation**: If FFmpeg stitching becomes bottleneck
- **New Azure Features**: If Azure Video Analyzer or similar services become available
- **Architecture Changes**: If Azure IoT Operations introduces new edge storage patterns

**Review Schedule**: Quarterly review (next review: April 2026)

## References

### Internal Documentation

- [Media Capture Service README](../../../src/500-application/503-media-capture-service/README.md)
- [Video Capture Query Blueprint](../../../blueprints/video-capture-query/README.md)
- [Component Integration Flow](../../../blueprints/video-capture-query/diagrams/02-component-integration-flow.md)
- [Deployment Sequence](../../../blueprints/video-capture-query/diagrams/06-deployment-sequence.md)

### External References

- [Azure Container Storage Accelerator Documentation](https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/)
- [Azure Blob Storage Lifecycle Management](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)
- [ONVIF Specification](https://www.onvif.org/specs/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)

### Architecture Decision Context

This ADR documents the proposed architectural approach for continuous video capture query implementation. The proposed solution includes:

- Rust-based continuous recorder
- ACSA-based edge-to-cloud sync
- Dual query paths (MQTT + REST API)
- Python SDK for Data Scientists
- Comprehensive deployment automation (Terraform + Helm)

This architecture is currently being validated through the Customer PoC deployment and will inform future customer implementations.

**Related ADRs**: None (first ADR for video capture domain in this repository)
