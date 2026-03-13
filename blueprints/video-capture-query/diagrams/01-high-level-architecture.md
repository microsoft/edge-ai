# High-Level Architecture Diagram

This diagram provides a complete overview of the video capture query solution, showing all major components and their relationships.

## System Components

### Data Scientist Environment

- **Query Request**: Data Scientists submit queries like "Get video from camera-01 on Jan 20, 10:00-10:30"
- **Video Analysis**: Jupyter/Python notebooks for analyzing retrieved video segments

### Edge Environment (Factory/Site)

#### Camera Infrastructure

- **Camera-01, Camera-02, Camera-N**: ONVIF/RTSP cameras continuously streaming video
- Multiple camera support with standardized ONVIF protocol

#### Kubernetes Cluster (K3s/AKS-EE)

- **Azure IoT Operations**:
  - Device Registry for camera management
  - MQTT Broker for communication
- **Media Capture Service**:
  - Continuous recording of camera streams
  - Creates 5-minute video segments
  - Writes to ACSA volume for automatic cloud sync

### Azure Cloud

#### Blob Storage (Multi-Tier)

- **Hot Tier (0-7 days)**: Fast access for recent video, $0.018/GB/month
- **Cool Tier (7-30 days)**: Lower cost for less frequently accessed video, $0.01/GB/month
- **Archive Tier (30-365 days)**: Lowest cost for long-term storage, $0.0015/GB/month
- **Automatic lifecycle management** moves data between tiers based on age

#### Video Query API

- Azure Function for processing historical video queries
- FFmpeg-based video stitching for assembling segments into continuous clips

#### Optional Enhancement

- **Azure Video Indexer**: AI-powered search and indexing for advanced video analysis

## Data Flow Patterns

### Continuous Recording Flow

```
Cameras → Media Capture Service → ACSA → Hot Storage → Cool Storage → Archive Storage
```

### Query Flow

```
Data Scientist → Video Query API → Blob Storage → Stitched Video → Analysis
```

### Optional AI Enhancement

```
Blob Storage → Video Indexer → Enhanced Search Capabilities
```

## Key Architecture Principles

1. **Continuous Recording**: 24/7 recording with automatic segmentation
2. **Cost Optimization**: Automatic lifecycle management reduces storage costs by 91% over one year
3. **ACSA Integration**: Seamless edge-to-cloud sync without custom code
4. **Flexible Querying**: Time-based queries for precise video retrieval
5. **Scalability**: Support for multiple cameras with hash-based storage distribution
