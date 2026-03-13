# Deployment Sequence Diagram

This diagram shows the complete 5-phase deployment sequence for the video capture query solution, from infrastructure provisioning to production validation.

## Deployment Overview

**Total Deployment Time**: 2-4 hours (automated)
**Deployment Tool**: Terraform blueprints
**Target Environment**: Azure + Edge (K3s/AKS-EE)

## Phase 1: Cloud Infrastructure (20-30 minutes)

Deploy all cloud resources using the Terraform blueprint:

### Step 1.1: Configure Terraform Variables

Create `terraform.tfvars` file:

```hcl
environment     = "dev"
resource_prefix = "videocapture"
location        = "eastus2"
instance        = "001"

tags = {
  project     = "video-capture-query"
  environment = "dev"
  managed_by  = "terraform"
}
```

### Step 1.2: Deploy via Terraform Blueprint

**Blueprint Components** (deployed as single unit):

- `000-cloud/000-resource-group`: Resource group
- `000-cloud/030-data`: Storage account with lifecycle policies
- `000-cloud/040-messaging`: Azure Functions only (Event Grid and Event Hubs disabled for video-only blueprint)

**Terraform Deployment**:

```bash
# Navigate to blueprint directory
cd blueprints/video-capture-query/terraform

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

**What Gets Created**:

- Resource group with tags and policies
- Storage account with:
  - Zone-redundant storage (ZRS)
  - Hot/Cool/Archive tiers
  - Blob versioning enabled
  - Container: `media-capture-data`
  - Lifecycle policies (7-day Cool, 30-day Archive, 365-day Delete)
- Azure Function App:
  - Python 3.11 runtime
  - Consumption plan
  - Storage account binding
  - Managed identity

**Outputs** (captured by Terraform):

```bash
terraform output storage_account_name
terraform output storage_connection_string
terraform output function_app_name
terraform output function_app_url
```

### Step 1.3: Deploy Function App Code

After infrastructure is deployed, deploy the Video Query API code:

```bash
# Navigate to function app directory
cd ../../../src/500-application/520-video-query-api

# Get function app name from Terraform
FUNCTION_APP=$(cd ../../../blueprints/video-capture-query/terraform && terraform output -raw function_app_name)

# Deploy function code
func azure functionapp publish $FUNCTION_APP --python
```

**Validation**:

```bash
# Get function app URL
FUNCTION_URL=$(cd blueprints/video-capture-query/terraform && terraform output -raw function_app_url)

# Test health endpoint
curl https://$FUNCTION_URL/api/health
# Expected: {"status": "healthy"}
```

## Phase 2: Edge Infrastructure (30-45 minutes)

### Step 2.1: K3s Cluster Setup

**Component**: `100-edge/100-cncf-cluster`

- Provision K3s cluster:
  - 1 control plane node
  - 2 worker nodes (optional)
- Install base components:
  - Calico network plugin
  - Local-path provisioner
  - MetalLB load balancer
- Configure kubeconfig

**Manual Steps**:

```bash
# On each edge node
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

**Validation**:

```bash
kubectl get nodes
# Expected: All nodes Ready
```

### Step 2.2: Azure Arc Connection

**Component**: `100-edge/100-cncf-cluster` (Arc enablement)

- Connect K3s to Azure Arc
- Install Arc agents
- Configure Azure connectivity
- Set up Arc extensions

**Terraform Apply**:

```bash
terraform apply -target=azurerm_arc_kubernetes_cluster.main
```

**Validation**:

```bash
az connectedk8s show --name <cluster-name> --resource-group <rg>
# Expected: connectivityStatus: Connected
```

### Step 2.3: Azure IoT Operations

**Component**: `100-edge/110-iot-ops`

- Deploy IoT Operations operator
- Install MQTT broker
- Configure broker listeners:
  - Port 1883 (MQTT)
  - Port 8883 (MQTTS)
- Set up device registry

**Validation**:

```bash
kubectl get pods -n azure-iot-operations
# Expected: All pods Running
```

### Step 2.4: ACSA Configuration

**Component**: `100-edge/110-iot-ops` (storage configuration)

- Create ACSA-enabled PersistentVolume
- Configure cloud sync settings:
  - Target: Azure Blob Storage
  - Sync interval: 60 seconds
  - Retry policy: Exponential backoff
- Mount volume to namespace

**YAML Example**:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-capture-backed-acsa
spec:
  capacity:
    storage: 100Gi
  storageClassName: acsa-storage
  acsa:
    storageAccountName: mediastore123
    containerName: media-capture-data
    syncInterval: 60s
```

**Validation**:

```bash
kubectl get pv media-capture-backed-acsa
# Expected: STATUS: Bound
```

## Phase 3: Device Configuration (10-15 minutes)

### Step 3.1: Camera Registration

**Component**: `100-edge/111-assets`

- Discover ONVIF cameras on network
- Register camera assets:
  - Camera-01: 192.168.101.10
  - Camera-02: 192.168.101.11
- Configure camera profiles:
  - RTSP URL
  - Credentials (stored in Key Vault)
  - Stream settings

**Validation**:

```bash
kubectl get assets -n azure-iot-operations
# Expected: camera-01, camera-02 Ready
```

### Step 3.2: Camera Endpoints

**Component**: `100-edge/111-assets`

- Create asset endpoints for each camera
- Test RTSP connectivity
- Validate ONVIF discovery

**Validation**:

```bash
ffmpeg -i rtsp://192.168.101.10:554/stream -t 5 -f null -
# Expected: No errors, video frames decoded
```

## Phase 4: Application Deployment (15-20 minutes)

### Step 4.1: Media Capture Service

**Component**: `500-application/503-media-capture-service`

- Build Rust container image
- Push to Azure Container Registry
- Deploy to Kubernetes:
  - 1 replica per camera
  - ACSA volume mount
  - Resource limits: 2 CPU, 4Gi RAM
- Configure environment:
  - Camera RTSP URLs
  - ACSA mount path: `/media-capture-backed-acsa`
  - Segment duration: 300 seconds
  - MQTT broker endpoint

**Deployment**:

```bash
# Get storage connection string from Terraform
cd blueprints/video-capture-query/terraform
STORAGE_CONNECTION=$(terraform output -raw storage_connection_string)

# Create namespace
kubectl create namespace azure-iot-operations --dry-run=client -o yaml | kubectl apply -f -

# Create storage credentials secret
kubectl create secret generic video-storage-credentials \
  --from-literal=connection-string="$STORAGE_CONNECTION" \
  --namespace=azure-iot-operations

# Deploy via Helm chart
helm upgrade --install media-capture \
  ../../src/500-application/503-media-capture-service/charts/media-capture-service \
  --namespace azure-iot-operations \
  --set mediaCapture.continuousRecording.enabled=true \
  --set mediaCapture.continuousRecording.segmentDurationSeconds=300 \
  --set mediaCapture.video.rtspUrl="rtsp://192.168.101.10:554/stream" \
  --set mediaCapture.video.cameraId="camera-01" \
  --set mediaCapture.video.cameraLocation="Building-A/Floor-1" \
  --set mediaCapture.storage.acsaVolumePath="/media-capture-backed-acsa"
```

**Validation**:

```bash
kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service
# Expected: media-capture-service-xxxxx Running

kubectl logs -n azure-iot-operations -l app.kubernetes.io/name=media-capture-service
# Expected: "Started continuous recording from camera-01"
```

### Step 4.2: MQTT Configuration

**Component**: `503-media-capture-service`

- Subscribe to topics:
  - `video/query/request`
  - `video/query/control`
- Publish to topics:
  - `video/query/response`
  - `video/status`

**Validation**:

```bash
# Using mosquitto_sub
kubectl exec -it mqtt-broker-0 -- mosquitto_sub -t "video/#" -v
# Expected: See status messages every 60 seconds
```

## Phase 5: Validation & Testing (30-60 minutes)

### Step 5.1: End-to-End Recording Test

**Objective**: Verify continuous recording and ACSA sync

**Test Steps**:

1. Wait 5 minutes for first segment
2. Check ACSA volume for MP4 file:

```bash
kubectl exec -it media-capture-camera-01 -- ls -lh /media-capture-backed-acsa/a1/camera-01/
# Expected: video-*.mp4 and video-*.json files
```

1. Wait 2 minutes for ACSA sync
2. Check Azure Blob Storage:

```bash
az storage blob list \
  --account-name mediastore123 \
  --container-name media-capture-data \
  --prefix a1/camera-01/ \
  --query "[].name"
# Expected: Same files appear in cloud
```

**Success Criteria**:

- ✅ Video segments created every 5 minutes
- ✅ Files appear in cloud within 2 minutes
- ✅ Metadata JSON files included

### Step 5.2: MQTT Query Test

**Objective**: Verify real-time query path

**Test Steps**:

1. Install Python SDK:

```bash
pip install edge-ai-video-query-sdk
```

1. Run query script:

```python
from video_query_sdk import VideoClient

client = VideoClient(mqtt_broker="192.168.102.100:1883")
result = client.get_video_mqtt(
    camera_id="camera-01",
    start_time="2026-01-09T10:00:00Z",
    duration_minutes=10
)
print(f"Found {len(result.segments)} segments")
for url in result.segment_urls:
    print(url)
```

**Success Criteria**:

- ✅ Query completes in < 1 second
- ✅ Returns 2 segment URLs (10 minutes = 2 × 5-minute segments)
- ✅ SAS URLs are valid and accessible

### Step 5.3: REST API Query Test

**Objective**: Verify historical query and stitching

**Test Steps**:

1. Call Video Query API:

```bash
curl -X POST https://<function-app>.azurewebsites.net/api/query-video \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "camera-01",
    "start_time": "2026-01-09T10:00:00Z",
    "end_time": "2026-01-09T10:30:00Z"
  }'
```

1. Download stitched video:

```bash
curl -o output.mp4 "<returned-sas-url>"
```

1. Validate video:

```bash
ffprobe output.mp4
# Expected: Duration: 00:30:00, Video: h264, 1920x1080, 30 fps
```

**Success Criteria**:

- ✅ API returns stitched video URL
- ✅ Video is exactly 30 minutes long
- ✅ No gaps or corruption between segments

### Step 5.4: Lifecycle Policy Test

**Objective**: Verify tier transitions (accelerated)

**Test Steps**:

1. Manually set blob tier to Cool:

```bash
az storage blob set-tier \
  --account-name mediastore123 \
  --container-name media-capture-data \
  --name a1/camera-01/2026/01/09/10/video-*.mp4 \
  --tier Cool
```

1. Query same video:

```bash
# Should still work but may have slight delay
curl -X POST https://<function-app>.azurewebsites.net/api/query-video ...
```

1. Check lifecycle policy:

```bash
az storage account management-policy show \
  --account-name mediastore123 \
  --resource-group <rg>
# Expected: Rules for 7-day Cool, 30-day Archive, 365-day Delete
```

**Success Criteria**:

- ✅ Cool tier videos are accessible
- ✅ Lifecycle policies are active
- ✅ Policy rules match specification

### Step 5.5: Failure Recovery Test

**Objective**: Verify resilience to network failures

**Test Steps**:

1. Simulate network partition:

```bash
# On edge node, block Azure connectivity
sudo iptables -A OUTPUT -d *.blob.core.windows.net -j DROP
```

1. Continue recording for 10 minutes
2. Check ACSA volume accumulation:

```bash
kubectl exec media-capture-camera-01 -- du -sh /media-capture-backed-acsa/
# Expected: Growing storage, ~50MB per 5 minutes
```

1. Restore connectivity:

```bash
sudo iptables -D OUTPUT -d *.blob.core.windows.net -j DROP
```

1. Monitor ACSA sync logs:

```bash
kubectl logs -n azure-iot-operations acsa-sync-pod
# Expected: "Syncing backlog: 10 files..."
```

**Success Criteria**:

- ✅ Recording continues during outage
- ✅ Files accumulate in ACSA volume
- ✅ Automatic sync resumes after recovery
- ✅ All files eventually reach cloud

## Deployment Rollback

### Rollback Phase 4 (Application)

```bash
# Uninstall Helm release
helm uninstall media-capture --namespace azure-iot-operations

# Delete secrets
kubectl delete secret video-storage-credentials --namespace azure-iot-operations
```

### Rollback Phase 3 (Devices)

```bash
kubectl delete assets --all -n azure-iot-operations
```

### Rollback Phase 2 (Edge)

```bash
# Note: Edge infrastructure typically deployed separately
# If using Terraform for edge:
terraform destroy -target=module.iot_ops
terraform destroy -target=azurerm_arc_kubernetes_cluster.main
```

### Rollback Phase 1 (Cloud)

```bash
# Navigate to blueprint directory
cd blueprints/video-capture-query/terraform

# Destroy all cloud infrastructure
terraform destroy
```

## Post-Deployment Configuration

### Monitoring Setup

1. Enable Azure Monitor Container Insights
2. Configure Prometheus scraping
3. Set up Grafana dashboards
4. Configure alerts:
   - Camera offline > 5 minutes
   - ACSA sync lag > 10 minutes
   - Storage capacity > 80%

### Security Hardening

1. Rotate managed identity credentials
2. Enable Azure Storage encryption at rest
3. Configure network policies in Kubernetes
4. Enable audit logging

### Documentation

1. Record deployed version tags
2. Document custom configurations
3. Create runbook for operations
4. Train operations team

## Deployment Checklist

- [ ] Phase 1: Cloud infrastructure deployed
- [ ] Phase 1: Storage account accessible
- [ ] Phase 1: Function app responding to health checks
- [ ] Phase 2: K3s cluster running
- [ ] Phase 2: Azure Arc connected
- [ ] Phase 2: IoT Operations pods running
- [ ] Phase 2: ACSA volume bound
- [ ] Phase 3: Cameras discovered and registered
- [ ] Phase 3: RTSP connectivity validated
- [ ] Phase 4: Media capture pods running
- [ ] Phase 4: MQTT topics active
- [ ] Phase 5: End-to-end recording working
- [ ] Phase 5: MQTT query successful
- [ ] Phase 5: REST API query successful
- [ ] Phase 5: Lifecycle policies active
- [ ] Phase 5: Failure recovery tested
- [ ] Monitoring configured
- [ ] Documentation complete
