# Media Capture Service Component

## Overview

The Media Capture Service is a Rust-based Kubernetes workload designed for video segment capture in Azure IoT Operations environments. This component subscribes to MQTT broker events to retrieve alert events and manual commands, extracting and saving video segments from live RTSP streams using an in-memory ring buffer.

## Component Information

- **Component ID**: `503-media-capture-service`
- **Category**: Application Workload
- **Framework**: Kubernetes
- **Dependencies**: Azure IoT Operations MQTT Broker, Azure Container Storage (ACSA)

## Key Features

- **MQTT Subscription**: Listens for alert events and manual commands via Azure IoT Operations MQTT broker
- **Video Ring Buffer**: Continuously buffers frames from RTSP video streams in memory for rapid segment extraction
- **Event-Driven Capture**: Extracts relevant video segments triggered by alert events or manual commands
- **Cloud Sync**: Automatically syncs captured video segments to Azure Blob Storage via ACSA

## Use Cases

- **Digital Inspection & Survey**: Automated quality control and visual inspection workflows
- **Alert-Driven Video Capture**: Event-based video evidence collection for anomaly detection
- **Operational Performance Monitoring**: Real-time video capture during performance anomalies
- **Predictive Maintenance**: Video evidence collection for equipment failure analysis

## Prerequisites

### Technical Prerequisites

- [Azure IoT Operations cluster](https://learn.microsoft.com/azure/iot-operations/overview-iot-operations) deployed and configured
- [Azure Container Registry (ACR)](https://learn.microsoft.com/azure/container-registry/) accessible and configured
- [Azure Container Storage enabled by Azure Arc (ACSA)](https://learn.microsoft.com/azure/azure-arc/container-storage/install-edge-volumes?tabs=single) deployed
- [Azure Storage Account](https://learn.microsoft.com/azure/storage/common/storage-account-overview) with media container created
- MQTT broker (aio-broker) operational in azure-iot-operations namespace
- RTSP camera streams available for testing
- [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/tasks/tools/) and [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) installed
- [Docker](https://docs.docker.com/get-docker/) for image building
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) for Azure operations

### Optional Development Prerequisites

- [Rustup and Cargo (version 1.80 or higher)](https://doc.rust-lang.org/cargo/) for local development and testing

### Organizational Prerequisites

- Rust development expertise (for code modifications and testing)
- Kubernetes operations knowledge for deployment and troubleshooting
- Video processing and RTSP streaming understanding
- Azure IoT Operations platform familiarity

## Component Structure

```text
src/500-application/503-media-capture-service/
├── README.md                           # This documentation
├── docker-compose.yml                  # Local development setup
├── .env                               # Environment configuration
├── scripts/                           # Deployment and configuration scripts
│   ├── deploy-media-capture-service.sh # Automated deployment script
│   ├── generate-env-config.sh         # Environment configuration generator
│   ├── media-capture-test-kubernetes.sh # Testing utilities for Kubernetes deployments
│   └── media-capture-test-docker-compose.sh # Testing utilities for Docker Compose
├── media-capture-backed-acsa/         # ACSA storage mount point
├── charts/                            # Helm chart deployment
│   └── media-capture-service/         # Helm chart for the service
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           └── service.yaml
└── services/                          # Service implementation
    └── media-capture-service/         # Main service directory
        ├── Cargo.toml                 # Rust dependencies
        ├── Dockerfile                 # Container image definition
        ├── run.sh                     # Service startup script
        ├── src/                       # Rust source code
        └── sample-data/               # Test data and examples
    └── yaml/                          # Azure Container Storage configuration
        ├── cloudBackedPVC.yaml
        └── mediaEdgeSubvolume.yaml
```

## Environment Setup

Before deploying the Media Capture Service, you need to configure the required environment variables. See the [Configuration](#configuration) section for complete environment variable documentation.

### Required Environment Variables

The following environment variables are **required** for all deployment methods:

```bash
# Azure Resources
export ACR_NAME="your-acr-name"                    # Azure Container Registry name
export STORAGE_ACCOUNT_NAME="your-storage-account" # Azure Storage Account name
export ST_ACCOUNT_RESOURCE_GROUP="your-storage-rg" # Storage Account resource group
export CLUSTER_NAME="your-cluster-name"            # Kubernetes cluster name
export CLUSTER_RESOURCE_GROUP="your-cluster-rg"    # Cluster resource group
```

### Optional Environment Variables

These variables have sensible defaults but can be customized:

```bash
# Deployment Configuration
export FIELD_NAMESPACE="azure-iot-operations"      # Kubernetes namespace
export IMAGE_NAME="media-capture-service"          # Container image name
export IMAGE_VERSION="latest"                      # Container image tag

# Video Processing
export RTSP_URL="rtsp://your-camera:8554/live"     # RTSP camera stream URL
export VIDEO_FPS="20"                              # Video frames per second
export BUFFER_SECONDS="120"                        # Video buffer duration
export CAPTURE_DURATION_SECONDS="10"               # Video capture duration
```

> **Note**: The `./scripts/generate-env-config.sh` script can generate a `.env` file with these variables and sensible defaults.

## Deployment

The Media Capture Service supports multiple deployment approaches to accommodate different environments and workflows:

- **Automated Deployment**: Recommended for most users - handles all setup steps automatically
- **Helm Chart Deployment**: For users who need more control or CI/CD integration
- **Manual Deployment**: For advanced users requiring custom configuration
- **Local Development**: Docker Compose setup for testing and development

### Automated Deployment (Recommended)

Use the automated deployment script for streamlined setup:

1. **Configure the [required environment variables](#required-environment-variables)** listed above
2. **Run the deployment script**:

```bash
./scripts/deploy-media-capture-service.sh
```

This script automatically handles:

- Building and pushing the container image to ACR
- Configuring Azure Container Storage (ACSA)
- Setting up storage roles and permissions
- Creating storage containers
- Generating environment configuration
- Deploying the Helm chart
- Verifying the deployment

> Note: The initial container image build takes about 71 minutes. This is expected because the Dockerfile compiles the multimedia stack (x264, FFmpeg, and OpenCV) from source with codec support and optimizations, downloading and building toolchain dependencies. Subsequent builds are significantly faster due to Docker layer caching. Pre-built images are intentionally not used due to project security guidelines (supply-chain provenance and vulnerability control).

**To uninstall**:

```bash
./scripts/deploy-media-capture-service.sh --uninstall/-u
```

### Helm Chart Deployment

For more control over the deployment process or when integrating with existing CI/CD pipelines:

#### Helm Prerequisites

- Kubernetes cluster with Azure IoT Operations installed
- Azure Container Registry (ACR) access
- Azure Container Storage Accelerator (ACSA) configured
- Helm 3.x installed
- kubectl configured for your cluster

#### Quick Start

1. **Configure the [required environment variables](#required-environment-variables)** and any [optional variables](#optional-environment-variables) needed
2. **Generate environment configuration** (optional):

   ```bash
   ./scripts/generate-env-config.sh
   ```

3. **Install with Helm**:

   ```bash
   # Navigate to the helm chart directory
   cd charts/media-capture-service

   # Install or upgrade the service using the Helm chart
   helm upgrade --install media-capture-service . \
     --namespace azure-iot-operations \
     --set image.repository="$ACR_NAME.azurecr.io/media-capture-service" \
     --set image.tag="latest" \
     --set mediaCapture.video.rtspUrl="rtsp://your-camera:8554/live"
   ```

#### Advanced Helm Deployment Examples

**Deploy with Custom RTSP Camera:**

```bash
helm install media-capture-service . \
  --namespace azure-iot-operations \
  --set mediaCapture.video.rtspUrl="rtsp://192.168.1.100:8554/stream1" \
  --set mediaCapture.video.fps=30 \
  --set mediaCapture.video.frameWidth=1920 \
  --set mediaCapture.video.frameHeight=1080
```

**Deploy with Custom Trigger Topics:**

```bash
helm install media-capture-service . \
  --namespace azure-iot-operations \
  --set-json 'mediaCapture.triggerTopics=["factory/line1/alert", "factory/line2/maintenance"]'
```

**Deploy with Custom Values File:**

Create `my-values.yaml`:

```yaml
image:
  repository: myacr.azurecr.io/media-capture-service
  tag: v1.2.0

mediaCapture:
  video:
    rtspUrl: "rtsp://production-camera:8554/main"
    fps: 25
    frameWidth: 1280
    frameHeight: 720
    bufferSeconds: 15
    captureDurationSeconds: 45

  mqtt:
    brokerHostname: "production-broker.azure-iot-operations"
    clientId: "production-media-capture"

  triggerTopics:
    - "production/alerts/security"
    - "production/alerts/quality"
    - "production/maintenance/required"
```

Deploy with custom values:

```bash
helm install media-capture-service . \
  --namespace azure-iot-operations \
  --values my-values.yaml
```

#### Helm Management Commands

1. **Verify Helm Deployment**:

   ```bash
   # Check release status
   helm status media-capture-service -n azure-iot-operations

   # View deployed resources
   kubectl get all -l app.kubernetes.io/name=media-capture-service -n azure-iot-operations
   ```

2. **Updates and Rollbacks**:

   ```bash
   # Upgrade with new image tag
   helm upgrade media-capture-service . \
     --namespace azure-iot-operations \
     --set image.tag=v1.1.0

   # View release history
   helm history media-capture-service -n azure-iot-operations

   # Rollback to previous version
   helm rollback media-capture-service -n azure-iot-operations
   ```

3. **Uninstall**:

   ```bash
   helm uninstall media-capture-service -n azure-iot-operations
   ```

#### Helm Chart Development

**Template Testing:**

```bash
# Render templates locally
helm template media-capture-service . --values values.yaml

# Dry run installation
helm install media-capture-service . --dry-run --debug

# Lint the chart
helm lint .
```

#### Multi-Camera Deployments

**Important**: Each media-capture-service deployment is configured for a **single camera**. To record from multiple cameras, deploy **separate instances** (not replicas).

**Why Not Use Replicas?**

Increasing replicas (e.g., `--set replicaCount=2`) for the same deployment will:

- ❌ Create duplicate recordings of the same camera
- ❌ Waste storage with identical video streams
- ❌ Potentially cause race conditions when writing to the same paths
- ❌ Not distribute load across multiple cameras

### Correct Approach: Separate Helm Releases

Deploy one Helm release per camera with unique configurations:

```bash
# Camera 1 - Front Entrance
helm install media-capture-camera-01 ./charts/media-capture-service \
  --namespace azure-iot-operations \
  --set mediaCapture.continuousRecording.cameraId=camera-01 \
  --set mediaCapture.video.rtspUrl=rtsp://camera-01.local:8554/live \
  --set mediaCapture.continuousRecording.cameraLocation=front-entrance

# Camera 2 - Loading Dock
helm install media-capture-camera-02 ./charts/media-capture-service \
  --namespace azure-iot-operations \
  --set mediaCapture.continuousRecording.cameraId=camera-02 \
  --set mediaCapture.video.rtspUrl=rtsp://camera-02.local:8554/live \
  --set mediaCapture.continuousRecording.cameraLocation=loading-dock

# Camera 3 - Warehouse
helm install media-capture-camera-03 ./charts/media-capture-service \
  --namespace azure-iot-operations \
  --set mediaCapture.continuousRecording.cameraId=camera-03 \
  --set mediaCapture.video.rtspUrl=rtsp://camera-03.local:8554/live \
  --set mediaCapture.continuousRecording.cameraLocation=warehouse
```

**Benefits of Separate Deployments:**

- ✅ Each camera records independently to unique storage paths
- ✅ Different camera configurations (resolution, FPS, retention)
- ✅ Independent scaling and resource allocation
- ✅ Isolated failures (one camera failure doesn't affect others)
- ✅ Camera-specific monitoring and troubleshooting

**Managing Multiple Deployments:**

```bash
# List all media capture deployments
helm list -n azure-iot-operations | grep media-capture

# Update specific camera configuration
helm upgrade media-capture-camera-01 ./charts/media-capture-service \
  --namespace azure-iot-operations \
  --reuse-values \
  --set mediaCapture.continuousRecording.segmentDurationSeconds=600

# Remove specific camera deployment
helm uninstall media-capture-camera-02 -n azure-iot-operations

# View logs for specific camera
kubectl logs -n azure-iot-operations -l app.kubernetes.io/instance=media-capture-camera-01
```

**Storage Organization:**

Each camera automatically organizes recordings by camera ID:

```text
/cloud-sync/video-recordings/
├── camera-01/
│   └── 2026/01/13/21/
│       ├── segment_2026-01-13T21:00:00Z_camera-01.mp4
│       └── segment_2026-01-13T21:05:00Z_camera-01.mp4
├── camera-02/
│   └── 2026/01/13/21/
│       └── segment_2026-01-13T21:00:00Z_camera-02.mp4
└── camera-03/
    └── 2026/01/13/21/
        └── segment_2026-01-13T21:00:00Z_camera-03.mp4
```

### Manual Deployment (Advanced)

For advanced users requiring custom configuration or legacy environments:

> **Note**: This approach is for advanced users who need fine-grained control over each deployment step. For most use cases, the automated deployment is recommended.

1. **Configure the [required environment variables](#required-environment-variables)**
2. **Build and Push Container Image**:

   ```bash
   # Navigate to service directory
   cd services/media-capture-service

   # Build the Docker image
   docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION .

   # Login to Azure Container Registry
   az acr login --name $ACR_NAME

   # Push the image
   docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION
   ```

3. **Connect to Kubernetes Cluster**:

   ```bash
   az connectedk8s proxy -n $CLUSTER_NAME -g $CLUSTER_RESOURCE_GROUP
   ```

4. **Configure Azure Container Storage (ACSA)**:

   Apply Persistent Volume Claims for cloud-backed storage:

   ```bash
   # Apply PVC for cloud-backed storage
   kubectl apply -f ./yaml/cloudBackedPVC.yaml
   ```

5. **Assign Storage Roles**:

   Configure necessary roles for ACSA and user access:

   ```bash
   # Configure ACSA roles (run deployment script for automated setup)
   ./scripts/deploy-media-capture-service.sh
   ```

6. **Create Storage Container**:

   If your storage account doesn't have a media container:

   ```bash
   az storage container create \
       --account-name $STORAGE_ACCOUNT_NAME \
       --name media \
       --auth-mode login
   ```

7. **Apply Subvolume Configuration**:

   Create subvolume using extension identity:

   ```bash
   # Update storage account name in file
   kubectl apply -f ./yaml/mediaEdgeSubvolume.yaml
   ```

8. **Deploy with Helm**:

   ```bash
   # Deploy using Helm chart
   helm upgrade --install media-capture-service ./charts/media-capture-service \
     --namespace $FIELD_NAMESPACE \
     --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
     --set image.tag="$IMAGE_VERSION"

   # Restart pods to ensure latest configuration
   kubectl delete pod -l app.kubernetes.io/name=media-capture-service -n $FIELD_NAMESPACE
   ```

## Development

### Local Development

For local development and testing, you can use either Docker Compose or direct Rust development:

#### Docker Compose Development (Recommended)

Docker Compose provides a complete local development environment with an integrated MQTT broker for testing without requiring a full Kubernetes cluster.

**Components Included:**

- **setup-resources**: Initialization container that prepares the local environment
- **mosquitto-broker**: Local Eclipse Mosquitto MQTT broker for testing
- **media-capture-service**: The main application service

**Quick Start:**

1. **Generate Environment Configuration**:

   ```bash
   # Generate environment configuration with defaults
   ./scripts/generate-env-config.sh

   # Optional: Customize the generated .env file for local testing
   # Edit .env to adjust RTSP_URL, video parameters, etc.
   ```

2. **Run with Docker Compose**:

   ```bash
   # Start the service
   docker compose up -d

   # View logs
   docker compose logs -f media-capture-service

   # Make changes and rebuild
   docker compose build media-capture-service
   docker compose up -d media-capture-service

   # Stop the service
   docker compose down
   ```

**Automatic Configuration:** Docker Compose automatically overrides several environment variables from the `.env` file to enable local development with the included Mosquitto broker:

- `AIO_BROKER_HOSTNAME` → `mosquitto-broker` (targets local container)
- `AIO_BROKER_TCP_PORT` → `1883` (non-TLS port)
- `AIO_MQTT_USE_TLS` → `false` (disables TLS for local testing)

This means you can maintain production-ready values in your `.env` file while Docker Compose automatically adapts them for local development.

#### Testing with Docker Compose

**Automated Testing Scripts:**

```bash
# Quick test scenarios
./scripts/media-capture-test-docker-compose.sh alert          # Test alert trigger (current time)
./scripts/media-capture-test-docker-compose.sh alert-past     # Test alert trigger (5 seconds ago)
./scripts/media-capture-test-docker-compose.sh analytics      # Test analytics disabled trigger
./scripts/media-capture-test-docker-compose.sh manual         # Test manual trigger

# Advanced usage with options
./scripts/media-capture-test-docker-compose.sh -u -5 -l       # Test alert 5 seconds ago with local time
./scripts/media-capture-test-docker-compose.sh -f analytics-disabled.json -m analytics_disabled

# Show all available options
./scripts/media-capture-test-docker-compose.sh --help
```

**Manual MQTT Testing:**

```bash
# Basic alert trigger test
docker exec mosquitto-broker mosquitto_pub -h localhost -p 1883 \
  -t "alerts/trigger" \
  -m '{"timestamp": "2025-08-16T01:00:00Z", "alert": true, "confidence": 0.95}'

# Test with different trigger topics
docker exec mosquitto-broker mosquitto_pub -h localhost -p 1883 \
  -t "custom/topic" \
  -m '{"event": "custom_trigger", "timestamp": "2025-08-16T01:00:00Z"}'

# Monitor all MQTT traffic
docker exec mosquitto-broker mosquitto_sub -h localhost -p 1883 -t "#" -v
```

**Volume Persistence:**

The service uses the following volume mounts:

- `./resources/media:/cloud-sync/media` - Media file storage (persistent across restarts)
- `mosquitto-data:/mosquitto/data` - MQTT broker data persistence
- Sample data is mounted read-only for testing

Media files captured by the service will be stored in `./resources/media/` on the host system and persist across container restarts.

**Custom Configuration:**

For additional customization, create a `docker-compose.override.yml` file:

```yaml
version: '3.8'
services:
  media-capture-service:
    environment:
      - RUST_LOG=debug
      - VIDEO_FPS=30
```

#### Direct Rust Development

```bash
# Navigate to the service directory
cd services/media-capture-service

# Install development dependencies (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install libopencv-dev ffmpeg

# Run unit tests
cargo test

# Build for development
cargo build

# Run locally (requires proper environment setup)
cargo run
```

### Unit Tests

Run the test suite to validate core functionality:

```bash
# Navigate to service directory
cd services/media-capture-service

# Run all tests
cargo test --verbose

# Run specific test modules
cargo test video_ring_buffer
cargo test video_processor
cargo test multi_trigger
```

**Note**: Tests require OpenCV and FFmpeg system libraries. See the [OpenCV installation guide](https://docs.opencv.org/master/df/d65/tutorial_table_of_content_introduction.html) and [FFmpeg download page](https://ffmpeg.org/download.html) for installation instructions.

### Manual Alert Testing

Test video capture using the provided test scripts:

```bash
# Navigate to scripts directory
cd scripts

# Update alert timestamp and trigger capture
export ALERT_TRIGGER_TOPIC="alerts/trigger"
export FIELD_NAMESPACE="azure-iot-operations"

# Use the test trigger script
./media-capture-test-kubernetes.sh -u -5 -t $ALERT_TRIGGER_TOPIC -f ../services/media-capture-service/sample-data/alert-true.json -l
```

The `-u -5` flag sets the alert timestamp to 5 seconds ago to align with buffered video frames.

## Common Issues

### High Buffer Capacity Warnings

When seeing `Ring buffer at 100% capacity` warnings:

1. **Expected Behavior**: This is normal when video streams match configured FPS rates
2. **Solutions**:
   - Increase `BUFFER_SECONDS` for more video history
   - Decrease `VIDEO_FPS` if high frame rates aren't needed
   - Reduce frame resolution (`FRAME_WIDTH`/`FRAME_HEIGHT`)
   - Increase container memory limits

### Video Segment Time Alignment

The service uses sophisticated timing to extract relevant video segments:

- **Alert Timestamp**: Actual event time from alert payload
- **Video Feed Delay**: Compensates for stream latency (`VIDEO_FEED_DELAY_SECONDS`)
- **Capture Duration**: Total video segment length (`CAPTURE_DURATION_SECONDS`)

**Example Calculation** (default settings):

- Alert at 12:00:00
- Segment: 11:59:50 to 12:00:05 (15 seconds total)
- Includes 5s delay compensation + 10s capture duration

### Storage Integration Issues

1. **Verify ACSA Configuration**:

   ```bash
   kubectl get pvc -n azure-iot-operations
   kubectl describe pvc cloud-backed-claim -n azure-iot-operations
   ```

2. **Check Storage Account Access**:

   ```bash
   az storage container show --account-name $STORAGE_ACCOUNT_NAME --name video-recordings --auth-mode login
   ```

3. **Monitor File Sync**:

   ```bash
   kubectl exec -it deployment/media-capture-service -n azure-iot-operations -- ls -la /cloud-sync/video-recordings/
   ```

4. **Verify Cloud Storage Integration**:

   ```bash
   # Monitor logs for successful capture
   kubectl logs -l app.kubernetes.io/name=media-capture-service -n azure-iot-operations

   # Verify files in Azure Storage (using Azure CLI)
   az storage blob list --account-name $STORAGE_ACCOUNT_NAME --container-name video-recordings --auth-mode login
   ```

### Cloud Storage Sync Troubleshooting

When video recordings are not appearing in Azure Blob Storage, follow this diagnostic workflow:

#### 1. Verify Service is Running and Recording

Check if the media-capture-service pod is running and actively recording:

```bash
# Check pod status
kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service

# Check if service is scaled up (should show 1/1 replicas)
kubectl get deployment media-capture-service -n azure-iot-operations

# If scaled down (0/0), scale up to enable recording
kubectl scale deployment media-capture-service -n azure-iot-operations --replicas=1
```

#### 2. Check Local Recording on Pod

Verify files are being created locally before checking cloud sync:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service -o jsonpath='{.items[0].metadata.name}')

# Check if files are being written to local storage
kubectl exec -n azure-iot-operations $POD_NAME -- ls -lh /cloud-sync/video-recordings/

# Check for recent files (adjust camera ID as needed)
kubectl exec -n azure-iot-operations $POD_NAME -- find /cloud-sync/video-recordings/ -name "*.mp4" -o -name "*.mkv" -mmin -10

# Check total storage usage
kubectl exec -n azure-iot-operations $POD_NAME -- du -sh /cloud-sync/video-recordings/
```

#### 3. Review Service Logs

Check for recording activity and errors:

```bash
# View recent logs
kubectl logs -n azure-iot-operations $POD_NAME --tail=100

# Follow logs in real-time
kubectl logs -n azure-iot-operations $POD_NAME --follow

# Look for specific events
kubectl logs -n azure-iot-operations $POD_NAME | grep -E "(Recording started|segment saved|error|failed)"
```

#### 4. Understand ACSA Sync Behavior

**Important**: Files written to the ACSA-backed PVC are **not synced instantly** to Azure Blob Storage.

- **Sync Delay**: Can take several minutes depending on file size and network conditions
- **Local First**: Files are written to local PVC first, then synced asynchronously by ACSA
- **No Immediate Visibility**: Recent files may not appear in Azure Portal or CLI immediately

```bash
# Check ACSA PVC status
kubectl get pvc -n azure-iot-operations | grep -E "(NAME|cloud-backed)"

# Verify PVC is bound and using cloud-backed storage class
kubectl describe pvc pvc-acsa-cloud-backed -n azure-iot-operations
```

#### 5. Verify Storage Account Network Access

The storage account may have network restrictions preventing access from certain locations:

```bash
# Check storage account network settings
az storage account show --name $STORAGE_ACCOUNT_NAME \
  --query "{publicNetworkAccess:publicNetworkAccess,allowSharedKeyAccess:allowSharedKeyAccess}" \
  --output table

# If publicNetworkAccess is Disabled and you don't have private connectivity configured,
# ACSA uploads can fail with 403 AuthorizationFailure.
# Use Azure CLI with auth-mode login to verify from an allowed network.
az storage blob list --account-name $STORAGE_ACCOUNT_NAME \
  --container-name video-recordings \
  --auth-mode login \
  --output table
```

**Common Network Issues**:

- `publicNetworkAccess: Disabled` can block both Azure Portal browsing and ACSA edge-to-cloud uploads
- IP allowlists may block your current location
- Use `--auth-mode login` with Azure CLI to verify access (subject to network rules)

#### 6. Check ACSA Sync Controller Logs

If files exist locally but never appear in cloud storage, check ACSA sync status:

```bash
# Check Arc Container Storage pods (operator + per-PVC worker)
kubectl get pods -n azure-arc-containerstorage

# Check EdgeSubvolume health and backlog
kubectl get edgesubvolumes -A
kubectl get edgesubvolume media -o yaml

# Tail logs from the per-PVC worker pod (datamover container)
WORKER_POD=$(kubectl get pods -n azure-arc-containerstorage -o name | grep '^pod/w-pvc-acsa-cloud-backed' | head -n 1 | cut -d/ -f 2)
kubectl logs -n azure-arc-containerstorage $WORKER_POD -c datamover --tail=200
```

#### 7. Verify Storage Account Credentials

Ensure ACSA has proper credentials to access the storage account:

```bash
# ACSA uses the Azure Arc Container Storage extension managed identity.
# If EdgeSubvolume status shows AuthorizationFailure, validate the extension identity has
# Storage Blob Data Contributor on the target storage account.

# Inspect EdgeSubvolume errors (look for AuthorizationFailure)
kubectl get edgesubvolume media -o jsonpath='{.status.fileErrors[0].error}' && echo
```

#### 8. Test End-to-End Sync

Force a test recording and monitor sync:

```bash
# Trigger a manual recording by publishing MQTT message (if configured)
# Or wait for scheduled continuous recording segments

# Monitor file creation locally
watch -n 5 "kubectl exec -n azure-iot-operations $POD_NAME -- find /cloud-sync/video-recordings/ -name '*.mp4' -o -name '*.mkv' -mmin -5 | wc -l"

# Wait 3-5 minutes, then check Azure storage
az storage blob list --account-name $STORAGE_ACCOUNT_NAME \
  --container-name video-recordings \
  --auth-mode login \
  --query "[?properties.lastModified >= '$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)'].{name:name, size:properties.contentLength, modified:properties.lastModified}" \
  --output table
```

#### Common Issues and Solutions

| Issue                               | Symptoms                                    | Solution                                                        |
|-------------------------------------|---------------------------------------------|-----------------------------------------------------------------|
| **Service scaled down**             | No new files being created                  | Scale deployment to 1 replica                                   |
| **RTSP stream unavailable**         | No recording activity in logs               | Verify camera RTSP URL is accessible from pod                   |
| **ACSA not configured**             | PVC in Pending state                        | Deploy and configure Azure Container Storage                    |
| **Storage network blocked**         | Can't see blobs in Portal                   | Use Azure CLI with `--auth-mode login`                          |
| **Storage public access disabled**  | ACSA logs show `AuthorizationFailure` (403) | Enable public network access or configure private connectivity  |
| **Sync delay**                      | Local files exist, cloud empty              | Wait 3-5 minutes for ACSA sync to complete                      |
| **Storage credentials invalid**     | ACSA controller errors                      | Verify storage account connection in extension config           |
| **Retention policy deleting files** | Files disappear quickly                     | Adjust `localRetentionHours` in values.yaml (default: 24 hours) |

#### Quick Diagnostic Script

Run this script to get a comprehensive status check:

```bash
#!/bin/bash
echo "=== Media Capture Service Status ==="
kubectl get deployment media-capture-service -n azure-iot-operations

echo -e "\n=== Pod Status ==="
kubectl get pods -n azure-iot-operations -l app=media-capture-service

POD_NAME=$(kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service -o jsonpath='{.items[0].metadata.name}')

if [ -n "$POD_NAME" ]; then
  echo -e "\n=== Local Storage Usage ==="
  kubectl exec -n azure-iot-operations $POD_NAME -- du -sh /cloud-sync/video-recordings/ 2>/dev/null || echo "Pod not ready or path not accessible"

  echo -e "\n=== Recent Files (last 10 minutes) ==="
  kubectl exec -n azure-iot-operations $POD_NAME -- find /cloud-sync/video-recordings/ \( -name "*.mp4" -o -name "*.mkv" \) -mmin -10 2>/dev/null | wc -l

  echo -e "\n=== Recent Logs ==="
  kubectl logs -n azure-iot-operations $POD_NAME --tail=20 2>/dev/null
else
  echo "No running pod found"
fi

echo -e "\n=== ACSA PVC Status ==="
kubectl get pvc -n azure-iot-operations | grep -E "(NAME|cloud-backed)"

echo -e "\n=== ACSA Controller Status ==="
kubectl get pods -n azure-arc-containerstorage -l app=acsa-controller
```

### Docker Compose Issues

#### Common Docker Compose Problems

1. **Port 1883 already in use**: Another MQTT broker may be running. Stop it or change the port mapping.
2. **Permission issues**: Ensure Docker has access to the `./resources/` directory.
3. **Video capture fails**: Check that the RTSP_URL is accessible from within the container.
4. **MQTT connection issues**: Verify the mosquitto broker is running with `docker compose logs mosquitto-broker`.

#### Docker Compose Troubleshooting Commands

```bash
# View all service logs
docker compose logs

# Follow logs for specific service
docker compose logs -f media-capture-service

# View MQTT broker logs
docker compose logs mosquitto-broker

# Stop and remove volumes for clean restart
docker compose down -v
```

### Helm Chart Issues

#### Common Helm Problems

- **Pod not starting**: Check image pull secrets and repository access
- **MQTT connection failed**: Verify broker hostname and authentication
- **Storage issues**: Ensure ACSA and PVC are properly configured
- **Video capture not working**: Check RTSP URL accessibility

#### Helm Troubleshooting Commands

```bash
# Check release status
helm status media-capture-service -n azure-iot-operations

# View deployed resources
kubectl get all -l app.kubernetes.io/name=media-capture-service -n azure-iot-operations

# Check pod logs
kubectl logs -l app.kubernetes.io/name=media-capture-service -n azure-iot-operations

# Debug template rendering
helm template media-capture-service . --values values.yaml
```

## Configuration

### Environment Variables

The Media Capture Service uses environment variables for configuration. These can be set in the `.env` file for Docker Compose deployment or configured in the Helm chart values:

| **Environment Variable**       | **Description**                                                                          | **Default Value**                                                 |
|--------------------------------|------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| `AIO_BROKER_HOSTNAME`          | Hostname of the MQTT broker.                                                             | `aio-broker.azure-iot-operations`                                 |
| `AIO_BROKER_TCP_PORT`          | TCP port for the MQTT broker.                                                            | `18883`                                                           |
| `AIO_TLS_CA_FILE`              | Path to the CA certificate file for TLS communication with the MQTT broker.              | `/var/run/certs/ca.crt`                                           |
| `AIO_SAT_FILE`                 | Path to the service account token file for MQTT authentication.                          | `/var/run/secrets/tokens/mq-sat`                                  |
| `RUST_LOG`                     | Logging level for the application.                                                       | `info`                                                            |
| `TRIGGER_TOPICS`               | JSON array of MQTT topics to subscribe to for triggering video capture.                  | `["xyz/+/+/+/+/alert/trigger", "xyz/+/+/+/+/analytics_disabled"]` |
| `MEDIA_CLOUD_SYNC_DIR`         | Directory inside the pod where media files or video segments are synced to the cloud.    | `/cloud-sync/media`                                               |
| `RTSP_URL`                     | RTSP URL for the live video stream to buffer.                                            | `rtsp://mock-camera-fof.eastus2.azurecontainer.io:8554/live`      |
| `VIDEO_FPS`                    | Frames per second for the video buffer.                                                  | `20`                                                              |
| `FRAME_WIDTH`                  | Frame width for buffered video.                                                          | `896`                                                             |
| `FRAME_HEIGHT`                 | Frame height for buffered video.                                                         | `512`                                                             |
| `BUFFER_SECONDS`               | Number of seconds of video to keep in the buffer (for segment extraction).               | `120`                                                             |
| `AIO_MQTT_CLIENT_ID`           | MQTT client ID for the service.                                                          | `media-capture-service`                                           |
| `CAPTURE_DURATION_SECONDS`     | Duration (in seconds) of video segment to extract on alert/manual trigger.               | `10`                                                              |
| `VIDEO_FEED_DELAY_SECONDS`     | Seconds to offset alert timestamp for video delay compensation.                          | `5`                                                               |
| `BUFFER_CLEANUP_INTERVAL_SECS` | Interval in seconds between cleanup operations for old frames in the buffer.             | `60`                                                              |
| `MAX_OLD_FRAMES_AGE_SECS`      | Maximum age (in seconds) for frames in the buffer before they're removed during cleanup. | `300`                                                             |

### Key Configuration Notes

- **AIO MQTT Variables**: Configure secure communication with Azure IoT Operations MQTT broker
- **Timing Variables**: `BUFFER_SECONDS` and `CAPTURE_DURATION_SECONDS` control video buffering and segment extraction
- **Video Feed Delay**: `VIDEO_FEED_DELAY_SECONDS` compensates for typical stream latency
- **Trigger Topics**: `TRIGGER_TOPICS` accepts JSON array of MQTT topics for event-driven capture
- **Cleanup Parameters**: `BUFFER_CLEANUP_INTERVAL_SECS` and `MAX_OLD_FRAMES_AGE_SECS` manage memory usage

### Helm Chart Configuration

For Helm deployments, configuration is managed through the `values.yaml` file. Key configuration sections include:

#### Core Settings

| Parameter          | Description                | Default                                |
|--------------------|----------------------------|----------------------------------------|
| `image.repository` | Container image repository | `acr.azurecr.io/media-capture-service` |
| `image.tag`        | Container image tag        | `latest`                               |
| `image.pullPolicy` | Image pull policy          | `Always`                               |
| `namespace`        | Kubernetes namespace       | `azure-iot-operations`                 |
| `replicaCount`     | Number of replicas         | `1`                                    |

#### Image Configuration

```yaml
image:
  repository: your-acr.azurecr.io/media-capture-service
  tag: latest
  pullPolicy: Always
```

#### MQTT Configuration

| Parameter                          | Description                | Default                           |
|------------------------------------|----------------------------|-----------------------------------|
| `mediaCapture.mqtt.brokerHostname` | MQTT broker hostname       | `aio-broker.azure-iot-operations` |
| `mediaCapture.mqtt.brokerTcpPort`  | MQTT broker port           | `18883`                           |
| `mediaCapture.mqtt.clientId`       | MQTT client identifier     | `media-capture-client`            |
| `mediaCapture.mqtt.tlsCaFile`      | TLS CA certificate path    | `/var/run/certs/ca.crt`           |
| `mediaCapture.mqtt.satFile`        | Service account token path | `/var/run/secrets/tokens/mq-sat`  |

```yaml
mediaCapture:
  mqtt:
    brokerHostname: aio-broker.azure-iot-operations
    brokerTcpPort: 18883
    clientId: media-capture-service
    tlsCaFile: /var/run/certs/ca.crt
    satFile: /var/run/secrets/tokens/mq-sat
```

#### Video Processing Configuration

| Parameter                                   | Description           | Default                        |
|---------------------------------------------|-----------------------|--------------------------------|
| `mediaCapture.video.rtspUrl`                | RTSP stream URL       | `rtsp://mock-camera:8554/live` |
| `mediaCapture.video.fps`                    | Frames per second     | `20`                           |
| `mediaCapture.video.frameWidth`             | Video frame width     | `896`                          |
| `mediaCapture.video.frameHeight`            | Video frame height    | `512`                          |
| `mediaCapture.video.bufferSeconds`          | Video buffer duration | `10`                           |
| `mediaCapture.video.captureDurationSeconds` | Capture duration      | `30`                           |

```yaml
mediaCapture:
  video:
    rtspUrl: rtsp://your-camera:8554/live
    fps: 20
    frameWidth: 896
    frameHeight: 512
    bufferSeconds: 120
    captureDurationSeconds: 10
    feedDelaySeconds: 5
```

#### Storage Configuration

| Parameter                           | Description                      | Default                |
|-------------------------------------|----------------------------------|------------------------|
| `mediaCapture.storage.cloudSyncDir` | Cloud sync directory             | `/cloud-sync/media`    |
| `mediaCapture.triggerTopics`        | MQTT topics that trigger capture | `["topic1", "topic2"]` |

#### Integration with Azure IoT Operations

This service integrates with:

- **Azure IoT MQ Broker**: For MQTT message consumption
- **Azure Container Storage Accelerator**: For persistent media storage
- **Service Account Tokens**: For secure authentication
- **Trust Bundles**: For TLS certificate management

### Testing Configuration

#### Unit Test Coverage

The test suite validates core functionality across multiple modules:

#### `src/video_ring_buffer.rs`

- **Buffer Logic**: Verifies that the video ring buffer correctly pushes frames, maintains its maximum size, and drops the oldest frames when full.
- **Frame Selection**: Ensures correct selection of frames by timestamp and retrieval of the latest frame time.

#### `src/video_writer.rs`

- **Segment Extraction & Writing**: Tests that `write_buffered_video` returns `Ok(false)` when the buffer is empty (no frames written) and `Ok(true)` when frames are present and a file is written.
- **File Naming**: Verifies that the output filename includes the event ID when provided.
- **Return Value & Logging**: Ensures the boolean return value is correct and supports accurate downstream logging (e.g., logs a warning if no frames are written).

#### `src/video_processor.rs`

- **Trait Implementation**: Confirms that the `TimeParamWorker` trait returns the expected time parameters and event ID for video segment extraction. (Buffer and writer logic are tested in their respective modules.)

#### `src/multi_trigger.rs`

- **Multiple Trigger Format Support**: Tests the service's ability to handle different trigger message formats from various topics.
- **Time Parameter Calculation**: Validates the calculation of video segment parameters, ensuring proper extraction window with appropriate before/after buffer around the event timestamp.
- **Event ID Extraction**: Verifies correct extraction of unique event IDs from different message formats for file naming.
- **Error Handling**: Tests error cases such as missing devices array, missing timestamp, and fallback to default values when environment variables are unset.

### Memory Management Improvements

The Media Capture Service includes several improvements to memory management:

1. **Automatic Frame Cleanup**
   - A background task periodically removes frames older than a configurable age
   - Prevents unbounded memory growth for long-running instances
   - Configurable via `BUFFER_CLEANUP_INTERVAL_SECS` and `MAX_OLD_FRAMES_AGE_SECS`

2. **Memory Usage Monitoring**
   - Buffer capacity warnings at high utilization (>90%)
   - Minimized lock duration for buffer operations to reduce contention
   - Warning logs when buffer grows unusually fast

#### Running Tests

```bash
# Navigate to service directory
cd services/media-capture-service

# Run the tests using Cargo
cargo test

# Review the test results to ensure all tests pass
cargo test --verbose
```
