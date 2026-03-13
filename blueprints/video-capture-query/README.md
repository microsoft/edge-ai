---
title: Video Capture Query Blueprint
description: Complete end-to-end deployment for continuous video recording from cameras with time-based query capabilities enabling Data Scientists to retrieve historical video segments
author: Edge AI Team
ms.date: 2026-01-08
ms.topic: reference
keywords:
  - video capture
  - camera recording
  - time-based query
  - azure storage
  - azure functions
  - ffmpeg
  - continuous recording
  - iot operations
estimated_reading_time: 15
---

## Video Capture Query Blueprint

This blueprint provides a complete solution for continuous video recording from cameras with time-based query capabilities. It enables Data Scientists to request video from specific cameras at specific locations for defined timeframes (e.g., "capture video from camera-01 at location-a on January 20th from 10:00 to 10:30").

The solution combines edge recording infrastructure with cloud storage and query APIs to deliver historical video segments on demand.

## Architecture

This blueprint implements a continuous recording architecture that captures video 24/7 and stores segments in Azure Blob Storage with automatic lifecycle management for cost optimization.

### High-Level Architecture

```mermaid
graph TB
    subgraph DS["👨‍🔬 Data Scientist"]
        Request["🔍 Query Request<br/>'Get video from camera-01<br/>on Jan 20, 10:00-10:30'"]
        Analysis["📊 Video Analysis<br/>Jupyter/Python"]
    end

    subgraph Edge["🏭 Edge Environment (Factory/Site)"]
        subgraph Cameras["📹 Camera Infrastructure"]
            Cam1["Camera-01<br/>ONVIF/RTSP"]
            Cam2["Camera-02<br/>ONVIF/RTSP"]
            CamN["Camera-N<br/>ONVIF/RTSP"]
        end

        subgraph K8s["☸️ Kubernetes (K3s/AKS-EE)"]
            AIO["Azure IoT Operations<br/>Device Registry<br/>MQTT Broker"]
            MediaSvc["Media Capture Service<br/>Continuous Recording<br/>5-min segments"]
        end
    end

    subgraph Azure["☁️ Azure Cloud"]
        subgraph Storage["💾 Blob Storage"]
            Hot["Hot Tier (0-7d)<br/>Fast Access"]
            Cool["Cool Tier (7-30d)<br/>Lower Cost"]
            Archive["Archive Tier (30-365d)<br/>Lowest Cost"]
        end

        VideoAPI["⚡ Video Query API<br/>Azure Function<br/>FFmpeg Stitching"]

        subgraph ML["🤖 Optional Enhancement"]
            VideoIndexer["Azure Video Indexer<br/>AI-Powered Search"]
        end
    end

    Cam1 -->|RTSP Stream| MediaSvc
    Cam2 -->|RTSP Stream| MediaSvc
    CamN -->|RTSP Stream| MediaSvc

    AIO <-->|MQTT| MediaSvc
    MediaSvc -->|5-min segments| Hot

    Hot -->|Auto-tier after 7d| Cool
    Cool -->|Auto-tier after 30d| Archive

    Request -->|REST API| VideoAPI
    VideoAPI -->|Query blobs by timestamp| Storage
    VideoAPI -->|Stitch segments| VideoAPI
    VideoAPI -->|SAS URL| Request
    Request -->|Download & Analyze| Analysis

    Storage -.->|Optional| VideoIndexer
    VideoIndexer -.->|Enhanced Search| Request

    style Request fill:#fff9c4
    style MediaSvc fill:#fff4e1
    style VideoAPI fill:#f3e5f5
    style Hot fill:#ffebee
    style Cool fill:#e3f2fd
    style Archive fill:#f3e5f5
    style Analysis fill:#e8f5e9
```

### Component Integration Flow

```mermaid
graph TB
    subgraph Edge["Edge Environment"]
        Camera["📹 ONVIF Camera<br/>camera-01<br/>RTSP Stream"]
        DeviceReg["🔧 Device Registry<br/>111-assets<br/>Camera Config"]
        MediaCapture["🎬 Media Capture Service<br/>503-media-capture-service<br/>Continuous Recording"]
        MQTTBroker["📨 MQTT Broker<br/>Azure IoT Operations"]
        ACSA["💾 ACSA Volume<br/>/media-capture-backed-acsa<br/>Edge-to-Cloud Auto-Sync"]
    end

    subgraph Cloud["Azure Cloud"]
        BlobStorage["☁️ Blob Storage<br/>Video Segments<br/>Lifecycle Policies"]
        VideoAPI["⚡ Video Query API<br/>Azure Function<br/>520-video-query-api"]
    end

    subgraph DataScientist["Data Scientist Workstation"]
        SDK["🐍 Python SDK<br/>920-video-query-sdk"]
        Jupyter["📊 Jupyter Notebook<br/>Analysis Tools"]
    end

    Camera -->|RTSP Stream| MediaCapture
    DeviceReg -.->|Camera Config| Camera
    MediaCapture -->|Subscribe| MQTTBroker
    SDK -->|Publish Request| MQTTBroker
    MQTTBroker -->|Capture Request| MediaCapture
    MediaCapture -->|Write MP4 + JSON| ACSA
    ACSA -->|Auto-Sync to Cloud| BlobStorage
    MediaCapture -->|Response| MQTTBroker
    MQTTBroker -->|Blob URL| SDK
    SDK -->|Query Historical| VideoAPI
    VideoAPI -->|List & Download| BlobStorage
    VideoAPI -->|Stitch & Return| SDK
    SDK -->|Video URL| Jupyter

    style Camera fill:#e1f5ff
    style MediaCapture fill:#fff4e1
    style BlobStorage fill:#e8f5e9
    style VideoAPI fill:#f3e5f5
    style SDK fill:#fff9c4
```

### Blob Storage Organization & Lifecycle

```mermaid
graph TB
    subgraph BlobContainer["📦 Blob Container: video-recordings"]
        subgraph Hash1["342/"]
            subgraph Cam1["camera-01/"]
                subgraph Year1["2026/"]
                    subgraph Month1["01/"]
                        subgraph Day1["20/"]
                            Hour10["10/<br/>segment_2026-01-20T10:00:00Z_camera-01.mp4<br/>segment_2026-01-20T10:05:00Z_camera-01.mp4<br/>segment_2026-01-20T10:10:00Z_camera-01.mp4"]
                            Hour11["11/<br/>segment_2026-01-20T11:00:00Z_camera-01.mp4"]
                        end
                        Day21["21/"]
                    end
                end
            end
        end

        subgraph Hash2["789/"]
            subgraph Cam2["camera-02/"]
                subgraph Year2["2026/"]
                    subgraph Month2["01/"]
                        Day22["20/<br/>10/<br/>11/"]
                    end
                end
            end
        end
    end

    subgraph Tags["🏷️ Blob Index Tags"]
        Tag1["camera_id: camera-01<br/>start_time: 2026-01-20T10:00:00Z<br/>end_time: 2026-01-20T10:05:00Z"]
        Tag2["camera_id: camera-01<br/>start_time: 2026-01-20T10:05:00Z<br/>end_time: 2026-01-20T10:10:00Z"]
    end

    Hour10 -.->|Tagged| Tag1
    Hour10 -.->|Tagged| Tag2

    subgraph Lifecycle["♻️ Lifecycle Policy"]
        Hot["🔥 Hot (7 days)<br/>$0.018/GB/month<br/>Fast access"]
        Cool["❄️ Cool (30 days)<br/>$0.01/GB/month<br/>Slower access"]
        Archive["📦 Archive (90 days)<br/>$0.0015/GB/month<br/>Rare access"]
        Delete["🗑️ Delete (365 days)<br/>Auto-cleanup"]
    end

    Hour10 -->|Age: 0-7d| Hot
    Hot -->|Age: 7-30d| Cool
    Cool -->|Age: 30-90d| Archive
    Archive -->|Age: >365d| Delete

    style Hour10 fill:#e1f5ff
    style Tag1 fill:#fff9c4
    style Hot fill:#ffebee
    style Cool fill:#e3f2fd
    style Archive fill:#f3e5f5
    style Delete fill:#fafafa
```

### Data Flow

```mermaid
flowchart LR
    subgraph DataScientist["👨‍🔬 Data Scientist Workflow"]
        DS_IDE["💻 Jupyter Notebook<br/>Python SDK"]
        DS_Query["📝 Query Definition<br/>camera_id: camera-01<br/>start: 2026-01-20T10:00<br/>end: 2026-01-20T10:30"]
        DS_Video["🎬 Video Analysis<br/>Frame-by-frame<br/>ML Inference"]
    end

    subgraph Cloud["☁️ Azure Cloud Processing"]
        API["⚡ Video Query API<br/>Azure Function"]
        Blob["💾 Blob Storage<br/>6 segments found<br/>10:00-10:30"]
        FFmpeg["🔧 FFmpeg Stitcher<br/>Concat 6 segments"]
        SAS["🔐 Generate SAS URL<br/>24-hour expiry"]
    end

    subgraph Edge["🏭 Edge Recording"]
        Camera["📹 Camera-01"]
        Recorder["🎬 Continuous Recorder<br/>24/7 Recording<br/>5-min segments"]
        ACSAVolume["💾 ACSA Volume<br/>/media-capture-backed-acsa"]
        Upload["📤 ACSA Auto-Sync<br/>Background Upload"]
    end

    Camera -->|RTSP Stream| Recorder
    Recorder -->|Write MP4 every 5min| ACSAVolume
    ACSAVolume -->|Auto-Sync| Upload
    Upload -->|Cloud Sync| Blob

    DS_IDE -->|1. Define Query| DS_Query
    DS_Query -->|2. REST API Call| API
    API -->|3. List blobs| Blob
    Blob -->|4. Return 6 segments| API
    API -->|5. Download segments| Blob
    API -->|6. Stitch| FFmpeg
    FFmpeg -->|7. Merged video| API
    API -->|8. Upload temp| Blob
    Blob -->|9. Generate SAS| SAS
    SAS -->|10. Return URL| API
    API -->|11. Video URL| DS_IDE
    DS_IDE -->|12. Download| Blob
    DS_IDE -->|13. Analyze| DS_Video

    style DS_IDE fill:#fff9c4
    style API fill:#f3e5f5
    style Blob fill:#c8e6c9
    style FFmpeg fill:#e1f5ff
    style Recorder fill:#fff4e1
    style DS_Video fill:#ffebee
```

## Components

This blueprint orchestrates the following cloud infrastructure components:

| Component          | Purpose                                                            | Source Location                                                            |
|--------------------|--------------------------------------------------------------------|----------------------------------------------------------------------------|
| **Resource Group** | Creates Azure resource group for all resources                     | [src/000-cloud/000-resource-group](../../src/000-cloud/000-resource-group) |
| **Data Storage**   | Azure Storage Account for video recordings with lifecycle policies | [src/000-cloud/030-data](../../src/000-cloud/030-data)                     |
| **Messaging**      | Azure Functions hosting for Video Query API                        | [src/000-cloud/040-messaging](../../src/000-cloud/040-messaging)           |

### Edge Components (Separate Deployment)

The following components are deployed separately to the edge Kubernetes cluster:

| Component                 | Purpose                                                           | Source Location                                                                                      |
|---------------------------|-------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| **Camera Assets**         | ONVIF camera registration in Azure IoT Operations Device Registry | [src/100-edge/111-assets](../../src/100-edge/111-assets)                                             |
| **Media Capture Service** | Continuous video recording service with FFmpeg and ACSA sync      | [src/500-application/503-media-capture-service](../../src/500-application/503-media-capture-service) |

### Application Components (Function Code Deployment)

| Component           | Purpose                                                          | Source Location                                                                                  |
|---------------------|------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| **Video Query API** | Azure Function for time-based video queries and FFmpeg stitching | [src/500-application/520-video-query-api](../../src/500-application/520-video-query-api)         |
| **Video Query SDK** | Python library for Data Scientists to query historical video     | [src/900-tools-utilities/920-video-query-sdk](../../src/900-tools-utilities/920-video-query-sdk) |

## Prerequisites

Before deploying this blueprint, ensure you have:

### Azure Subscription & Permissions

* Azure subscription with sufficient quota for:
  * Storage Account (Standard_LRS or higher)
  * Function App (Consumption or Premium plan)
  * Resource Group creation
* Permissions to create resources:
  * `Contributor` or `Owner` role on subscription or resource group
  * `Storage Blob Data Contributor` for blob access

### Tools & CLIs

* **Terraform** >= 1.5.0 (for infrastructure deployment)
* **Azure CLI** >= 2.50.0 (for authentication and resource management)
* **kubectl** >= 1.27.0 (for edge Kubernetes deployment)
* **Helm** >= 3.12.0 (for media capture service deployment)
* **Azure Functions Core Tools** >= 4.0 (for Function App deployment)
* **Python** >= 3.9 (for SDK usage)

### Edge Infrastructure

* Kubernetes cluster (K3s, AKS-EE, or AKS) with:
  * Azure IoT Operations installed
  * MQTT Broker running
  * Device Registry configured
* Network connectivity:
  * Edge to Azure cloud (for ACSA sync)
  * Edge to camera RTSP endpoints
  * Cameras accessible via ONVIF/RTSP protocols

### Camera Requirements

* ONVIF-compliant IP cameras or
* RTSP stream endpoints
* Network accessibility from edge cluster
* Credentials for authentication

## Deployment

### Step 1: Deploy Cloud Infrastructure (< 10 minutes)

Deploy Azure resources for video storage and query API:

```bash
# Navigate to blueprint terraform directory
cd blueprints/video-capture-query/terraform

# Initialize Terraform
terraform init

# Review and customize variables (optional)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy infrastructure
terraform apply \
  -var="environment=prod" \
  -var="resource_prefix=vidcap" \
  -var="location=eastus" \
  -var="recording_mode=continuous"

# Capture outputs for edge configuration
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
FUNCTION_URL=$(terraform output -raw video_query_function_url)
```

### Step 2: Deploy Edge Media Capture Service (< 5 minutes)

Configure and deploy the continuous recording service to your edge Kubernetes cluster:

```bash
# Create namespace (if not exists)
kubectl create namespace azure-iot-operations --dry-run=client -o yaml | kubectl apply -f -

# Deploy media capture service with continuous recording
helm install media-capture \
  ../../src/500-application/503-media-capture-service/charts/media-capture-service \
  --namespace azure-iot-operations \
  --set mediaCapture.continuousRecording.enabled=true \
  --set mediaCapture.continuousRecording.segmentDurationSeconds=300 \
  --set mediaCapture.continuousRecording.localRetentionHours=24 \
  --set mediaCapture.continuousRecording.cleanupIntervalMinutes=60 \
  --set mediaCapture.storage.cloudSyncDir=/cloud-sync/video-recordings \
  --set mediaCapture.video.rtspUrl="rtsp://camera-user:camera-pass@192.168.1.100:554/stream1"

# Verify deployment
kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service
```

**Configuration Options**:

* `segmentDurationSeconds`: Video segment duration (default: 300s / 5 min)
* `localRetentionHours`: How long to keep files locally before cleanup (default: 24 hours)
* `cleanupIntervalMinutes`: How often to check for old files to delete (default: 60 minutes)

**Note**: ACSA automatically uploads video files from the mounted volume to Azure Blob Storage. No storage connection strings or secrets are required - ACSA uses the cluster's managed identity. Local retention cleanup prevents disk space exhaustion while maintaining a buffer for network interruptions.

### Step 3: Deploy Video Query API Function (< 5 minutes)

Deploy the Azure Function code for video query and stitching:

```bash
# Navigate to function app directory
cd ../../src/500-application/520-video-query-api

# Deploy function code
func azure functionapp publish $FUNCTION_URL \
  --python

# Function app will use managed identity to access storage
# No connection strings needed - automatically configured by Terraform

# Verify deployment
func azure functionapp list-functions $FUNCTION_URL
```

### Step 4: Install Data Scientist SDK (< 2 minutes)

Install the Python SDK for querying historical video:

```bash
# Install from source
cd ../../src/900-tools-utilities/920-video-query-sdk
pip install -e .

# Or install from wheel (if available)
pip install video-query-sdk

# Verify installation
python -c "from video_query_sdk import VideoQueryClient; print('SDK installed successfully')"
```

### Step 5: Validate Deployment (< 5 minutes)

Test the end-to-end video capture and query workflow:

```bash
# Wait for first segment to be recorded (5 minutes)
sleep 300

# Query recent video using Python SDK
python <<EOF
from video_query_sdk import VideoQueryClient
from datetime import datetime, timedelta

client = VideoQueryClient(api_url="https://$FUNCTION_URL/api")

# Query video from 5 minutes ago
end_time = datetime.now()
start_time = end_time - timedelta(minutes=5)

try:
    video_url = client.get_video(
        camera_id="camera-01",
        start_time=start_time,
        end_time=end_time
    )
    print(f"✅ Video URL: {video_url}")
except Exception as e:
    print(f"❌ Error: {e}")
EOF

# Verify blob storage contains segments
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name video-recordings \
  --prefix "camera-01" \
  --query "[].name" \
  --output table
```

**Total deployment time: < 30 minutes**

## Usage

### Data Scientist Workflow

Data Scientists can query historical video using the Python SDK:

```python
from video_query_sdk import VideoQueryClient
from datetime import datetime
import cv2

# Initialize client
client = VideoQueryClient(api_url="https://your-function-app.azurewebsites.net/api")

# Query video from specific timeframe
video_url = client.get_video(
    camera_id="camera-01",
    start_time=datetime(2026, 1, 20, 10, 0, 0),
    end_time=datetime(2026, 1, 20, 10, 30, 0)
)

# Download video for analysis
video_path = client.download_video(video_url, local_path="./analysis_video.mp4")

# Perform video analysis with OpenCV
cap = cv2.VideoCapture(video_path)
frame_count = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Your analysis logic here
    # Example: Object detection, anomaly detection, etc.
    frame_count += 1

cap.release()
print(f"Processed {frame_count} frames")
```

See [terraform/examples/data-scientist-workflow.py](terraform/examples/data-scientist-workflow.py) for complete workflow examples.

### Query API Reference

**Endpoint**: `GET /video`

**Parameters**:

* `camera` (required): Camera identifier (e.g., "camera-01")
* `start` (required): Start timestamp (ISO 8601 format)
* `end` (required): End timestamp (ISO 8601 format)

**Response**:

```json
{
  "video_url": "https://storage.blob.core.windows.net/temp-videos/...",
  "duration": 1800,
  "segments": 6,
  "camera_id": "camera-01"
}
```

### Configuration Options

#### Recording Mode

The blueprint supports three recording modes:

| Mode               | Description                        | Use Case                           | Cost Impact           |
|--------------------|------------------------------------|------------------------------------|-----------------------|
| `continuous`       | 24/7 recording of all cameras      | Always-on surveillance, compliance | ~$16/year per camera  |
| `hybrid`           | Scheduled + on-demand recording    | Business hours recording           | ~$3-8/year per camera |
| `ring_buffer_only` | Real-time capture only (last 120s) | Alert-triggered capture            | $0 storage cost       |

Set via `recording_mode` variable:

```hcl
recording_mode = "continuous"  # Default
```

#### Segment Duration

Configure video segment size for optimal query performance:

```hcl
segment_duration_seconds = 300  # 5 minutes (default)
```

**Recommendations**:

* 300 seconds (5 min): Balanced performance and file count
* 60 seconds (1 min): Fine-grained queries, more files
* 900 seconds (15 min): Fewer files, coarser queries

#### Retention Policy

Configure video retention and lifecycle tiering:

```hcl
video_retention_days = 365  # Default: 1 year

# Automatic tiering (defined in component):
# - Hot tier: 0-7 days (fast access)
# - Cool tier: 7-30 days (slower access)
# - Archive tier: 30-365 days (rare access)
# - Auto-delete: after 365 days
```

## Cost Estimation

### Storage Costs (per camera)

**Assumptions**:

* Video bitrate: 2 Mbps
* Recording: 24/7 continuous
* Retention: 365 days with lifecycle policies

| Tier      | Duration     | Daily Size   | Monthly Cost    | Annual Cost     |
|-----------|--------------|--------------|-----------------|-----------------|
| Hot       | 7 days       | 21.6 GB      | $0.46           | $5.52           |
| Cool      | 23 days      | 66.4 GB      | $0.69           | $8.28           |
| Archive   | 335 days     | 966 GB       | $0.19           | $2.28           |
| **Total** | **365 days** | **1,054 GB** | **$1.34/month** | **$16.08/year** |

**Cost Optimization**: Lifecycle policies reduce costs by 90% compared to Hot-only storage ($160/year → $16/year per camera).

### Compute Costs

* **Azure Functions**: Consumption plan, pay-per-execution
  * ~$0.20 per million executions
  * Typical usage: ~10 queries/day = $0.60/month
* **Edge Compute**: Included in existing Kubernetes infrastructure

**Total estimated cost**: ~$17-20/year per camera with continuous recording.

## Troubleshooting

### Issue 1: Video segments not appearing in blob storage

**Symptoms**:

* Media capture service running but no blobs created
* Empty video-recordings container

**Diagnosis**:

```bash
# Check media capture service logs
kubectl logs -n azure-iot-operations -l app=media-capture-service --tail=100

# Verify ACSA sync status
kubectl describe pod -n azure-iot-operations -l app=media-capture-service | grep -A 10 "Events:"

# Test storage connection using managed identity
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name video-recordings \
  --auth-mode login
```

**Resolution**:

* Verify ACSA EdgeSubvolume is in "configured" state
* Check ACSA configuration and managed identity permissions
* Ensure network connectivity from edge to Azure
* Verify RTSP stream is accessible from media capture pod
* Check media capture service logs for recording errors

### Issue 2: Video query API returns 404 or timeout

**Symptoms**:

* API endpoint not responding
* Timeout errors when querying video

**Diagnosis**:

```bash
# Check Function App status
az functionapp show \
  --name $FUNCTION_URL \
  --resource-group $(terraform output -raw resource_group_name) \
  --query state

# View function logs
az functionapp log tail \
  --name $FUNCTION_URL \
  --resource-group $(terraform output -raw resource_group_name)

# Test function endpoint
curl https://$FUNCTION_URL/api/video?camera=camera-01&start=2026-01-20T10:00:00Z&end=2026-01-20T10:30:00Z
```

**Resolution**:

* Verify Function App deployment completed successfully
* Check Function App managed identity has Storage Blob Data Reader role
* Ensure Function App has network connectivity to storage account
* Review function logs for errors

### Issue 3: FFmpeg stitching fails or produces corrupted video

**Symptoms**:

* API returns error during video stitching
* Downloaded video is corrupted or won't play

**Diagnosis**:

```bash
# Check function logs for FFmpeg errors
az functionapp log tail \
  --name $FUNCTION_URL \
  --resource-group $(terraform output -raw resource_group_name) \
  | grep -i ffmpeg

# Verify segment codec consistency
ffprobe -v error -show_format -show_streams segment1.mp4
ffprobe -v error -show_format -show_streams segment2.mp4
```

**Resolution**:

* Ensure all segments have identical codec parameters
* Verify keyframe alignment in recording configuration (`-g 60 -sc_threshold 0`)
* Check segment files are not corrupted in blob storage
* Increase Function App timeout limit if needed (default: 5 minutes)

### Issue 4: High storage costs

**Symptoms**:

* Monthly storage bill higher than expected
* Blob storage size growing unexpectedly

**Diagnosis**:

```bash
# Check current storage usage by tier
az storage account blob-service-properties show \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $(terraform output -raw resource_group_name)

# List blobs by age
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name video-recordings \
  --query "[?properties.lastModified < '2025-12-01'].{name:name, tier:properties.blobTier, size:properties.contentLength}" \
  --output table
```

**Resolution**:

* Verify lifecycle policies are active and configured correctly
* Reduce video retention days if compliance allows
* Consider hybrid recording mode for non-critical cameras
* Implement video compression settings (reduce bitrate, resolution)

### Issue 5: Edge media capture service crashes or restarts

**Symptoms**:

* Media capture pods showing CrashLoopBackOff
* Frequent pod restarts
* OOMKilled status in pod events

**Diagnosis**:

```bash
# Check pod status and events
kubectl get pods -n azure-iot-operations -l app=media-capture-service
kubectl describe pod -n azure-iot-operations -l app=media-capture-service

# Check resource usage
kubectl top pod -n azure-iot-operations -l app=media-capture-service

# View pod logs
kubectl logs -n azure-iot-operations -l app=media-capture-service --previous
```

**Resolution**:

* Increase pod memory limits in Helm values (`resources.limits.memory`)
* Reduce number of concurrent camera streams
* Check RTSP stream stability from cameras
* Verify FFmpeg encoding settings not too CPU-intensive

### Issue 6: Slow query performance for historical video

**Symptoms**:

* Video queries taking > 10 seconds
* Timeout errors for large timeframe queries

**Diagnosis**:

```bash
# Check blob index tag availability
az storage blob show \
  --account-name $STORAGE_ACCOUNT \
  --container-name video-recordings \
  --name "camera-01/2026/01/20/10/segment_*.mp4" \
  --query tags

# Test query performance
time az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name video-recordings \
  --prefix "camera-01/2026/01/20/10"
```

**Resolution**:

* Verify blob index tags are enabled and populated
* Use prefix-based queries for timeframes < 1 hour
* Consider splitting large timeframe queries into smaller chunks
* Upgrade Function App to Premium plan for better performance

### Getting Help

* **Component Documentation**:
  * [Media Capture Service](../../src/500-application/503-media-capture-service/README.md)
  * [Video Query API](../../src/500-application/520-video-query-api/README.md)
  * [Video Query SDK](../../src/900-tools-utilities/920-video-query-sdk/README.md)
* **Azure IoT Operations**: [Microsoft Learn Documentation](https://learn.microsoft.com/azure/iot-operations/)
* **Azure Functions**: [Troubleshooting Guide](https://learn.microsoft.com/azure/azure-functions/functions-diagnostics)
* **Azure Storage**: [Performance Troubleshooting](https://learn.microsoft.com/azure/storage/common/troubleshoot-storage-performance)

## Advanced Configuration

### Multiple Camera Deployment

Configure multiple cameras in media capture service:

```yaml
# Helm values
cameras:
  - name: camera-01
    rtspUrl: rtsp://192.168.1.100:554/stream1
    location: factory-floor-a
  - name: camera-02
    rtspUrl: rtsp://192.168.1.101:554/stream1
    location: factory-floor-b
  - name: camera-03
    rtspUrl: rtsp://192.168.1.102:554/stream1
    location: warehouse-entrance
```

### Custom Video Encoding

Optimize video encoding for your use case:

```yaml
# High quality (higher storage cost)
videoEncoding:
  codec: libx264
  preset: slow
  crf: 18

# Balanced (default)
videoEncoding:
  codec: libx264
  preset fast
  crf: 23

# Low storage (lower quality)
videoEncoding:
  codec: libx264
  preset: ultrafast
  crf: 28
```

### Private Endpoint Access

Secure storage access using private endpoints:

```hcl
# Add to terraform configuration
storage_account_network_rules = {
  default_action = "Deny"
  ip_rules = []
  virtual_network_subnet_ids = [module.network.subnet_id]
}

storage_account_enable_private_endpoint = true
```

## Related Documentation

* [Blueprint Overview](../README.md) - General blueprint deployment patterns
* [Full Single Node Cluster Blueprint](../full-single-node-cluster/README.md) - Complete IoT Operations deployment
* [Media Capture Service](../../src/500-application/503-media-capture-service/README.md) - Detailed component documentation
* [Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/) - Platform documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
