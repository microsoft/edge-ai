---
title: Media Connector for Azure IoT Operations
description: Local development environment for testing Azure IoT Operations Media Connector with mock cameras, MQTT broker, and monitoring tools. Production deployment via blueprints.
author: Edge AI Team
ms.date: 11/12/2025
ms.topic: reference
estimated_reading_time: 12
keywords:
  - media-connector
  - azure-iot-operations
  - akri-connectors
  - docker-compose
  - rtsp
  - mqtt
  - development-environment
  - local-testing
---

## Media Connector for Azure IoT Operations

This directory provides a **local development and testing environment** for the Azure IoT Operations Media Connector using Docker Compose. It includes mock RTSP cameras, MQTT broker, and monitoring tools for development without requiring a full Kubernetes cluster.

**For production deployment**, the Media Connector is deployed via blueprints (e.g., `blueprints/full-single-node-cluster`) by enabling the Akri media connector feature.

## Overview

The Azure IoT Operations Media Connector makes images and video from various media sources available to other Azure IoT Operations components in a secure and performant manner. This implementation provides:

- **Multi-source media ingestion** from IP cameras, RTSP streams, media files, and edge-attached cameras
- **Real-time snapshot capture** with MQTT publishing for AI processing pipelines
- **Video clip recording** to local file system with Azure Container Storage integration
- **Live stream proxying** through RTSP/RTSPs endpoints for operator access
- **Device template management** for dynamic media source discovery and configuration
- **Secure authentication** support for camera access and stream management

## Architecture

```mermaid
graph TB
    subgraph "Media Sources"
        A[IP Cameras]
        B[RTSP Streams]
        C[Media Files]
        D[Edge Cameras]
    end

    subgraph "Azure IoT Operations"
        E[Media Connector]
        F[MQTT Broker]
        G[Device Registry]
        H[Asset Registry]
    end

    subgraph "Edge Processing"
        I[AI/ML Workloads]
        J[Video Analytics]
        K[Alert Systems]
    end

    subgraph "Storage & Streaming"
        L[Azure Container Storage]
        M[Media Server]
        N[Azure Blob Storage]
    end

    A --> E
    B --> E
    C --> E
    D --> E
    E --> F
    E --> G
    E --> H
    E --> L
    E --> M
    F --> I
    F --> J
    F --> K
    L --> N
    M --> O[Operator Dashboard]
```

## Features

### Media Source Types

| Source Type      | URL Examples                                                     | Authentication     | Description                                           |
|------------------|------------------------------------------------------------------|--------------------|-------------------------------------------------------|
| **IP Camera**    | `rtsp://192.168.1.100:554/stream1`                               | Basic Auth, Digest | Network-connected cameras with RTSP/HTTP interfaces   |
| **Edge Camera**  | `file://host/dev/video0`                                         | None               | USB, FireWire, MIPI, or proprietary interface cameras |
| **Media Server** | `rtsp://server:554/live/stream`                                  | Various            | Dedicated media streaming servers                     |
| **Media File**   | `http://server/snapshot.jpg`, `file://localhost/media/video.mp4` | Various            | Static or dynamic media files                         |
| **Media Folder** | `file://host/media/folder/`, `ftp://server/clips/`               | Various            | Directories containing media collections              |

### Task Types

| Task                 | Description                                  | Output                                 |
|----------------------|----------------------------------------------|----------------------------------------|
| **snapshot-to-mqtt** | Capture snapshots and publish to MQTT topics | MQTT messages with image data          |
| **clip-to-fs**       | Save video clips to local file system        | Video files in Azure Container Storage |
| **snapshot-to-fs**   | Save snapshots to local file system          | Image files in persistent storage      |
| **stream-to-rtsp**   | Proxy live streams to RTSP endpoints         | Real-time video streams                |
| **stream-to-rtsps**  | Proxy live streams to secure RTSP endpoints  | Encrypted video streams                |

### Integration Points

- **Azure IoT Operations MQTT Broker** - Real-time data streaming
- **Azure Device Registry** - Camera and source device management
- **Azure Asset Registry** - Media asset and metadata management
- **Azure Container Storage** - Persistent edge storage for clips and snapshots
- **Azure Arc-enabled Kubernetes** - Container orchestration and management

## Live Streaming with MediaMTX

The media connector supports live stream proxying through the `stream-to-rtsp` and `stream-to-rtsps` task types. These tasks require a **production media server deployment** when used in customer environments.

### When MediaMTX Deployment is Required

Deploy a dedicated media server (MediaMTX or equivalent) when:

- **Live operator access** - Operators need real-time video feeds for monitoring and decision-making
- **Multi-viewer scenarios** - Multiple users need simultaneous access to the same video stream
- **Stream aggregation** - Consolidating multiple camera feeds into a single accessible endpoint
- **Protocol conversion** - Converting between RTSP, HLS, WebRTC, or other streaming protocols

### Development Environment

For **local testing only**, the `docker-compose.yml` includes a MediaMTX container:

```yaml
mediamtx:
  image: bluenviron/mediamtx:latest
  ports:
    - "8557:8554"  # RTSP
    - "8888:8888"  # HLS
```

**Important**: This is a development convenience and not suitable for production deployments.

### Production Deployment Recommendations

For **customer production environments**:

1. **Deploy dedicated media server infrastructure** using:
   - MediaMTX (open source, RTSP/HLS/WebRTC support)
   - NGINX with RTMP module
   - Wowza Streaming Engine
   - Azure Media Services

2. **Reference the media server** in media connector assets:
   - Configure `stream-to-rtsp` tasks with media server endpoint
   - Set appropriate authentication and access controls
   - Enable TLS/encryption for `stream-to-rtsps` tasks

3. **Consider deployment patterns**:
   - **Edge-hosted**: Deploy media server on same Kubernetes cluster
   - **Cloud-hosted**: Use Azure Media Services or cloud-hosted streaming infrastructure
   - **Hybrid**: Edge buffering with cloud distribution

### When MediaMTX is NOT Required

Skip media server deployment when:

- Only using `snapshot-to-mqtt` or `clip-to-fs` tasks
- No live operator access needed
- Post-processing only workflows
- Batch video analysis scenarios

## Quick Start

### Local Development Environment

For **local testing without Kubernetes**:

```bash
# Start all development services
cd src/500-application/508-media-connector
docker compose up -d

# Verify services are running
docker compose ps

# View logs
docker compose logs -f

# Test mock RTSP camera
curl http://localhost:8554/

# Stop environment
docker compose down
```

### Production Deployment

**RECOMMENDED** - Deploy media connector using a two-step Infrastructure as Code approach:

1. **Deploy the connector template** (enables the media connector runtime)
2. **Configure devices and assets** (defines cameras and capture tasks)

#### Setup Prerequisites

1. Deploy the `full-single-node-cluster` blueprint (or another blueprint with IoT Operations)
2. Ensure media sources (cameras, RTSP streams) are accessible from the cluster

#### Step 1: Deploy the Media Connector Template

Choose one of two deployment options:

##### Option A: Simple Enablement (Recommended for Getting Started)

```bash
cd blueprints/full-single-node-cluster/terraform

# Edit terraform.tfvars
cat >> terraform.tfvars <<EOF
should_enable_akri_media_connector = true
EOF

terraform apply
```

This deploys the Akri Media Connector template with default settings using Microsoft Container Registry images.

##### Option B: Advanced Configuration

For custom images, MQTT configuration, or multiple connector instances, use `custom_akri_connectors`:

```hcl
# In terraform.tfvars
custom_akri_connectors = [
  {
    name              = "my-media-connector"
    type              = "media"
    image_tag         = "0.5.1"            # Override default version
    replicas          = 2                  # Multiple instances for HA
    log_level         = "debug"            # Enhanced logging
    mqtt_config = {                        # Custom MQTT settings
      host                   = "aio-broker.azure-iot-operations:18883"
      audience               = "aio-mq"
      ca_configmap           = "aio-ca-trust-bundle-test-only"
      keep_alive_seconds     = 60
      max_inflight_messages  = 100
      session_expiry_seconds = 600
    }
  }
]
```

Then apply:

```bash
terraform apply
```

#### Step 2: Configure Devices and Assets

After deploying the connector template, configure your cameras (devices) and capture tasks (assets):

```bash
cd blueprints/full-single-node-cluster/terraform

# Create or edit media-connector-assets.tfvars
# Copy example configuration (when available)
# cp media-connector-assets.tfvars.example media-connector-assets.tfvars
```

Add device and asset configurations using `namespaced_devices` and `namespaced_assets` variables:

```hcl
# In media-connector-assets.tfvars

# Define camera devices
namespaced_devices = [
  {
    name         = "warehouse-camera-01"
    display_name = "Warehouse Camera 01"
    enabled      = true
    endpoint = {
      name = "warehouse-camera-endpoint"
      authentication = {
        method = "UsernamePassword"
        username_secret_ref = { name = "camera-credentials", key = "username" }
        password_secret_ref = { name = "camera-credentials", key = "password" }
      }
      target_address = "rtsp://192.168.1.100:554/stream1"
    }
    # ... additional device properties
  }
]

# Define capture tasks (assets)
namespaced_assets = [
  {
    name         = "warehouse-camera-01-snapshots"
    display_name = "Warehouse Camera 01 Snapshots"
    enabled      = true
    device_ref = {
      device_name   = "warehouse-camera-01"
      endpoint_name = "warehouse-camera-endpoint"
    }
    datasets = [{
      name = "snapshots"
      dataset_configuration = "{\"taskType\":\"snapshot-to-mqtt\",\"intervalSeconds\":5,\"quality\":85}"
      destinations = [{ target = "Mqtt", configuration = { topic = "warehouse/camera-01/snapshots" } }]
    }]
  }
]
```

See the [Configuring Media Connector Assets](#configuring-media-connector-assets) section below for detailed examples.

Apply the device and asset configuration:

```bash
terraform apply -var-file="media-connector-assets.tfvars"
```

#### Verify

```bash
# Check deployed devices and assets
kubectl get devices,assets -n azure-iot-operations

# Check connector instances
kubectl get connectorinstance,connectortemplate -n azure-iot-operations

# View connector logs
kubectl logs -l app.kubernetes.io/name=media-connector -n azure-iot-operations --tail=100 -f

# Monitor MQTT messages
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  sh -c "mosquitto_sub --host aio-broker.azure-iot-operations --port 18883 \
         --username 'K8S-SAT' --pw \$(cat /var/run/secrets/tokens/broker-sat) \
         --cafile /var/run/certs/ca.crt --topic 'media/#' -v"
```

**Configuration Reference**: See `blueprints/full-single-node-cluster/terraform/media-connector-assets.tfvars.example`
for a complete example of all available configuration options including device and asset definitions.

## Configuring Media Connector Assets

When configuring media connector assets in your `terraform.tfvars` or `media-connector-assets.tfvars`, define devices for your cameras/media sources and assets for capture tasks.

### Device Configuration Example

Define RTSP cameras or other media sources as devices:

```hcl
namespaced_devices = [
  {
    name         = "warehouse-camera-01"
    display_name = "Warehouse Camera 01"
    enabled      = true
    endpoint = {
      name = "warehouse-camera-endpoint"
      authentication = {
        method = "UsernamePassword"
        username_secret_ref = {
          name = "camera-credentials"
          key  = "username"
        }
        password_secret_ref = {
          name = "camera-credentials"
          key  = "password"
        }
      }
      target_address = "rtsp://192.168.1.100:554/stream1"
    }
    description = "Warehouse main entrance camera"
    manufacturer = "Hikvision"
    model        = "DS-2CD2T85FWD-I8"
    serial_number = "DS2CD2T85FWDI820230101"
    attributes = {
      location   = "Warehouse Main Entrance"
      resolution = "1920x1080"
      frameRate  = "30"
    }
  }
]
```

### Asset Configuration Example

Define media capture tasks as assets:

```hcl
namespaced_assets = [
  {
    name         = "warehouse-camera-01-snapshots"
    display_name = "Warehouse Camera 01 Snapshots"
    enabled      = true
    device_ref = {
      device_name   = "warehouse-camera-01"
      endpoint_name = "warehouse-camera-endpoint"
    }
    description = "Snapshot capture from warehouse camera for AI processing"
    attributes = {
      assetType = "media-snapshots"
      location  = "Warehouse Main Entrance"
    }
    datasets = [
      {
        name                  = "snapshots"
        data_source           = ""  # Media connector uses device endpoint
        dataset_configuration = "{\"taskType\":\"snapshot-to-mqtt\",\"intervalSeconds\":5,\"quality\":85}"
        data_points           = []
        destinations = [
          {
            target = "Mqtt"
            configuration = {
              topic = "warehouse/camera-01/snapshots"
            }
          }
        ]
      }
    ]
  },
  {
    name         = "warehouse-camera-01-clips"
    display_name = "Warehouse Camera 01 Video Clips"
    enabled      = true
    device_ref = {
      device_name   = "warehouse-camera-01"
      endpoint_name = "warehouse-camera-endpoint"
    }
    description = "Video clip recording from warehouse camera"
    attributes = {
      assetType = "media-clips"
      location  = "Warehouse Main Entrance"
    }
    datasets = [
      {
        name                  = "clips"
        data_source           = ""  # Media connector uses device endpoint
        dataset_configuration = "{\"taskType\":\"clip-to-fs\",\"durationSeconds\":30,\"storagePath\":\"/clips\"}"
        data_points           = []
        destinations = []  # Clips stored to filesystem, not MQTT
      }
    ]
  }
]
```

### Task Types in Dataset Configuration

Configure different media connector tasks via `dataset_configuration` JSON:

| Task Type            | Configuration Example                                                                                   |
|----------------------|---------------------------------------------------------------------------------------------------------|
| **snapshot-to-mqtt** | `{"taskType":"snapshot-to-mqtt","intervalSeconds":5,"quality":85}`                                      |
| **clip-to-fs**       | `{"taskType":"clip-to-fs","durationSeconds":30,"storagePath":"/clips"}`                                 |
| **snapshot-to-fs**   | `{"taskType":"snapshot-to-fs","intervalSeconds":10,"quality":90,"storagePath":"/snapshots"}`            |
| **stream-to-rtsp**   | `{"taskType":"stream-to-rtsp","mediaServerEndpoint":"rtsp://mediamtx:8554/stream"}`                     |
| **stream-to-rtsps**  | `{"taskType":"stream-to-rtsps","mediaServerEndpoint":"rtsps://mediamtx:8555/stream","tlsEnabled":true}` |

**Complete Configuration Example**: See `blueprints/full-single-node-cluster/terraform/media-connector-assets.tfvars.example` for a production-ready configuration file with multiple cameras, authentication, and various task types.

## Local Development and Testing

### Development Quick Start

1. **Start development environment:**

   ```bash
   docker compose up -d
   ```

1. **Available services:**
   - RTSP Camera 1 (Pattern): `rtsp://admin:password@localhost:8554/pattern`
   - RTSP Camera 2 (Color Bars): `rtsp://admin:password@localhost:8555/colorbars`
   - RTSP Camera 3 (Moving Ball): `rtsp://admin:password@localhost:8556/ball`
   - HTTP Media Server: `http://localhost:8080`
   - MQTT Broker: `mqtt://localhost:1883` (anonymous access)
   - Grafana Dashboard: `http://localhost:3000` (admin/admin123) - **Local development only**
   - MinIO Console: `http://localhost:9001` (minioadmin/minioadmin123)

1. **Monitor MQTT messages:**

   ```bash
   # Subscribe to all media topics
   mosquitto_sub -h localhost -t "media/#" -v

   # Publish test message
   mosquitto_pub -h localhost -t "media/test" -m '{"test": "message"}'
   ```

### Testing RTSP Streams

> **Security Note**: The examples below include credentials in the command line for **local development convenience only**. Never use inline credentials in production environments.

**Local Development Testing:**

```bash
# Test stream with FFmpeg (local development only)
ffmpeg -i "rtsp://admin:password@localhost:8554/pattern" -t 10 -f null -

# Create snapshot (local development only)
ffmpeg -i "rtsp://admin:password@localhost:8554/pattern" -frames:v 1 -f image2 snapshot_%03d.jpg

# Test stream with VLC (local development only)
vlc "rtsp://admin:password@localhost:8554/pattern"
```

**Production Environment Best Practices:**

For production camera access, use secure authentication methods:

```bash
# Method 1: Use environment variables for credentials
export RTSP_USERNAME="camera-admin"
export RTSP_PASSWORD="$(az keyvault secret show --vault-name <vault> --name camera-password --query value -o tsv)"

ffmpeg -i "rtsp://${RTSP_USERNAME}:${RTSP_PASSWORD}@192.168.1.100:554/stream1" -t 10 -f null -

# Method 2: Use FFmpeg credentials file (avoids command-line exposure)
cat > ~/.ffmpeg_creds << EOF
rtsp://192.168.1.100:554/stream1
username=${RTSP_USERNAME}
password=${RTSP_PASSWORD}
EOF
chmod 600 ~/.ffmpeg_creds

ffmpeg -i "$(cat ~/.ffmpeg_creds | head -1)?$(cat ~/.ffmpeg_creds | tail -2 | tr '\n' '&')" -t 10 -f null -

# Method 3: Use digest authentication (preferred for production)
# Configure cameras to use digest authentication instead of basic auth
ffmpeg -rtsp_transport tcp -i "rtsp://192.168.1.100:554/stream1" \
  -user agent "FFmpeg" \
  -headers "Authorization: Digest username=\"${RTSP_USERNAME}\"" \
  -t 10 -f null -
```

**Media Connector Production Configuration:**

In production, camera credentials are managed through **Azure Key Vault** and automatically synced to Kubernetes:

1. **Create secrets in Azure Key Vault** (via Azure Portal, CLI, or operations experience UI):

   ```bash
   # Example: Create username secret in Azure Key Vault
   az keyvault secret set \
     --vault-name "<your-keyvault-name>" \
     --name "camera-username" \
     --value "camera-admin"

   # Example: Create password secret in Azure Key Vault
   az keyvault secret set \
     --vault-name "<your-keyvault-name>" \
     --name "camera-password" \
     --value "secure-password"
   ```

2. **Secrets are automatically synced** to Kubernetes via Azure Key Vault Secret Store extension

3. **Reference secrets in Device configuration** using the operations experience UI or Azure CLI

For detailed instructions on secret management, see [Manage secrets for your Azure IoT Operations deployment](https://learn.microsoft.com/en-us/azure/iot-operations/secure-iot-ops/howto-manage-secrets).

> **Note**: Terraform/Bicep automation for creating and syncing Azure Key Vault secrets to device configurations is planned for a future release. Currently, secrets must be created manually via Azure Portal, Azure CLI, or the operations experience UI. Track progress in the project backlog.

### Troubleshooting

```bash
# View all service logs
docker compose logs

# View specific service logs
docker compose logs mqtt-broker

# Check service status
docker compose ps

# Restart services
docker compose restart

# Stop and clean up
docker compose down

# Remove all data (destructive)
docker compose down -v
```

### Security Note for Development

> **Warning**: This configuration is for development only. Do not use in production.

This environment is configured for local development and testing:

- **MQTT Broker**: Anonymous access enabled (no authentication required)
- **Mock Credentials**: Simple passwords for RTSP cameras, Grafana, MinIO
- **No Encryption**: All connections use plain HTTP/MQTT (not HTTPS/MQTTS)
- **Local Monitoring**: Prometheus and Grafana included for development visibility only

**For Production Deployments:**

- Use Azure IoT Operations MQTT broker with managed authentication
- Deploy via blueprints with proper security configuration
- Enable TLS/encryption for all connections
- Use Azure Key Vault for credential management
- Use Arc-enabled monitoring with Azure Managed Grafana (see [Production Monitoring](#production-monitoring-with-azure-managed-grafana))

## Deployment Scenarios

The media connector can be deployed using either:

- **Simple enablement**: Set `should_enable_akri_media_connector = true` for default configuration
- **Advanced configuration**: Use `custom_akri_connectors` list for custom images, MQTT settings, or multiple instances

Specific camera and asset configuration is managed through **Device** and **Asset** resources defined in `media-connector-assets.tfvars`.

### Scenario 1: Basic Snapshot Capture

Deploy media connector with default settings and configure snapshot capture:

```bash
cd blueprints/full-single-node-cluster/terraform

# Enable media connector (simple flag approach)
cat >> terraform.tfvars <<EOF
should_enable_akri_media_connector = true
EOF

# Configure camera and snapshot asset in media-connector-assets.tfvars
# See "Configuring Media Connector Assets" section above for examples

terraform apply -var-file="media-connector-assets.tfvars"
```

### Scenario 2: Video Clip Recording

Configure video clip recording to persistent storage. This requires both device (camera) and asset (clip recording task) configuration:

```hcl
# In media-connector-assets.tfvars

# Define the security camera device
namespaced_devices = [
  {
    name         = "security-camera-01"
    display_name = "Security Camera 01"
    enabled      = true
    endpoint = {
      name = "security-camera-endpoint"
      authentication = {
        method = "UsernamePassword"
        username_secret_ref = {
          name = "camera-credentials"
          key  = "username"
        }
        password_secret_ref = {
          name = "camera-credentials"
          key  = "password"
        }
      }
      target_address = "rtsp://192.168.1.105:554/stream1"
    }
    description = "Security camera for motion-triggered recording"
  }
]

# Define the video clip recording asset
namespaced_assets = [
  {
    name         = "security-camera-clips"
    display_name = "Security Camera Video Clips"
    enabled      = true
    device_ref = {
      device_name   = "security-camera-01"
      endpoint_name = "security-camera-endpoint"
    }
    description = "Motion-triggered video clip recording"
    attributes = {
      assetType = "media-clips"
    }
    datasets = [
      {
        name                  = "motion-clips"
        data_source           = ""  # Media connector uses device endpoint
        dataset_configuration = "{\"taskType\":\"clip-to-fs\",\"durationSeconds\":60,\"storagePath\":\"/security/clips\"}"
        data_points           = []
        destinations          = []  # Clips stored to filesystem
      }
    ]
  }
]
```

### Scenario 3: Multi-Camera Deployment

Deploy multiple cameras with different capture configurations:

```hcl
# In media-connector-assets.tfvars
namespaced_devices = [
  {
    name         = "camera-entrance"
    display_name = "Main Entrance Camera"
    endpoint = {
      name = "entrance-endpoint"
      target_address = "rtsp://192.168.1.100:554/stream1"
      # ... authentication config
    }
  },
  {
    name         = "camera-warehouse"
    display_name = "Warehouse Floor Camera"
    endpoint = {
      name = "warehouse-endpoint"
      target_address = "rtsp://192.168.1.101:554/stream1"
      # ... authentication config
    }
  }
]

namespaced_assets = [
  {
    name       = "entrance-snapshots"
    device_ref = { device_name = "camera-entrance", endpoint_name = "entrance-endpoint" }
    datasets = [{
      name = "snapshots"
      dataset_configuration = "{\"taskType\":\"snapshot-to-mqtt\",\"intervalSeconds\":2,\"quality\":90}"
      destinations = [{ target = "Mqtt", configuration = { topic = "entrance/snapshots" } }]
    }]
  },
  {
    name       = "warehouse-snapshots"
    device_ref = { device_name = "camera-warehouse", endpoint_name = "warehouse-endpoint" }
    datasets = [{
      name = "snapshots"
      dataset_configuration = "{\"taskType\":\"snapshot-to-mqtt\",\"intervalSeconds\":5,\"quality\":85}"
      destinations = [{ target = "Mqtt", configuration = { topic = "warehouse/snapshots" } }]
    }]
  }
]
```

### Scenario 4: Live Streaming with MediaMTX

Configure live stream proxying for operator access (requires MediaMTX deployment). This requires both device (camera) and asset (streaming task) configuration:

```hcl
# In media-connector-assets.tfvars

# Define the control room camera device
namespaced_devices = [
  {
    name         = "control-room-camera"
    display_name = "Control Room Camera"
    enabled      = true
    endpoint = {
      name = "control-room-endpoint"
      authentication = {
        method = "UsernamePassword"
        username_secret_ref = {
          name = "camera-credentials"
          key  = "username"
        }
        password_secret_ref = {
          name = "camera-credentials"
          key  = "password"
        }
      }
      target_address = "rtsp://192.168.1.200:554/stream1"
    }
    description = "Control room monitoring camera for operator dashboard"
  }
]

# Define the live streaming asset
namespaced_assets = [
  {
    name         = "operator-view-stream"
    display_name = "Operator Dashboard Stream"
    enabled      = true
    device_ref = {
      device_name   = "control-room-camera"
      endpoint_name = "control-room-endpoint"
    }
    description = "Live stream proxy for operator dashboard access"
    attributes = {
      assetType = "media-stream"
    }
    datasets = [
      {
        name                  = "live-stream"
        data_source           = ""  # Media connector uses device endpoint
        dataset_configuration = "{\"taskType\":\"stream-to-rtsp\",\"mediaServerEndpoint\":\"rtsp://mediamtx-service:8554/control-room\"}"
        data_points           = []
        destinations          = []  # Stream proxied to MediaMTX
      }
    ]
  }
]
```

## Infrastructure Components

| Component             | Purpose                                    | Technology                       |
|-----------------------|--------------------------------------------|----------------------------------|
| **Media Connector**   | Core media ingestion service               | Azure IoT Operations             |
| **Device Templates**  | Camera discovery and configuration         | Azure Device Registry            |
| **Asset Definitions** | Media stream and metadata management       | Azure Asset Registry             |
| **Storage Volumes**   | Persistent storage for clips and snapshots | Azure Container Storage          |
| **MQTT Topics**       | Real-time data streaming                   | Azure IoT Operations MQTT Broker |
| **Proxy Services**    | Secure media access for operators          | Kubernetes Services              |

## Monitoring and Troubleshooting

### Production Monitoring with Azure Managed Grafana

When deploying via blueprints, the media connector integrates with Arc-enabled Kubernetes monitoring and Azure Managed Grafana automatically.

#### Monitoring Components Deployed by Blueprints

The `full-single-node-cluster` and related blueprints deploy:

- **Azure Monitor Workspace** - Managed Prometheus for metrics collection
- **Azure Managed Grafana** - Hosted Grafana instance with built-in dashboards
- **Log Analytics Workspace** - Centralized logging and log queries
- **Data Collection Rules** - Automated metrics and log collection from Arc-enabled cluster
- **Application Insights** - Application performance monitoring

#### Accessing Production Monitoring

After blueprint deployment, access monitoring resources:

```bash
# Get Grafana endpoint from Terraform outputs
terraform output -json | jq -r '.observability.value.grafana_endpoint'

# Or from Azure Portal
az grafana show \
  --name "<grafana-name>" \
  --resource-group "<resource-group>" \
  --query properties.endpoint -o tsv
```

#### Pre-configured Dashboards

Azure Managed Grafana includes these dashboards for Arc-enabled Kubernetes:

- **Kubernetes / Compute Resources / Cluster** - Cluster-wide resource usage
- **Kubernetes / Compute Resources / Namespace (Pods)** - Per-namespace pod metrics
- **Kubernetes / Compute Resources / Node (Pods)** - Per-node pod metrics
- **Kubernetes / Compute Resources / Pod** - Individual pod metrics and logs
- **Kubernetes / Networking / Pod** - Network traffic and connections

#### Custom Media Connector Dashboards

Create custom dashboards for media connector metrics:

1. **Navigate to Grafana endpoint** from Terraform outputs
2. **Create new dashboard** with Prometheus data source (auto-configured)
3. **Add panels** for media connector metrics:

```promql
# Active RTSP streams
sum(rate(media_connector_streams_active[5m])) by (namespace, pod)

# Snapshot capture rate
sum(rate(media_connector_snapshots_total[5m])) by (namespace, pod)

# Video clip recording rate
sum(rate(media_connector_clips_total[5m])) by (namespace, pod)

# MQTT publish success rate
sum(rate(media_connector_mqtt_publishes_total[5m])) by (namespace, pod)

# Error rates
sum(rate(media_connector_errors_total[5m])) by (namespace, pod, error_type)
```

#### Log Queries in Log Analytics

Query media connector logs from Log Analytics:

```kusto
// Media connector pod logs
ContainerLogV2
| where PodName startswith "media-connector"
| where ContainerName == "media-connector"
| project TimeGenerated, LogMessage, PodName, ContainerName
| order by TimeGenerated desc

// Error logs only
ContainerLogV2
| where PodName startswith "media-connector"
| where LogMessage contains "error" or LogMessage contains "ERROR"
| project TimeGenerated, LogMessage, PodName
| order by TimeGenerated desc

// MQTT publish failures
ContainerLogV2
| where PodName startswith "media-connector"
| where LogMessage contains "mqtt" and (LogMessage contains "fail" or LogMessage contains "error")
| project TimeGenerated, LogMessage, PodName
| order by TimeGenerated desc
```

#### Alert Rules

Configure alert rules in Azure Monitor for production monitoring:

```bash
# Example: Alert on high error rate
az monitor metrics alert create \
  --name "media-connector-high-error-rate" \
  --resource-group "<resource-group>" \
  --scopes "<aks-cluster-id>" \
  --condition "avg media_connector_errors_total > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "<action-group-id>"
```

### Health Checks

```bash
# Check media connector status
kubectl get pods -n azure-iot-operations -l app=media-connector

# Check device connectivity
kubectl get devices -n azure-iot-operations

# Check asset status
kubectl get assets -n azure-iot-operations

# Monitor MQTT traffic
kubectl logs -n azure-iot-operations deployment/aio-broker
```

### Common Issues

1. **Camera Connection Failed**

   ```bash
   # Check network connectivity
   kubectl exec -it media-connector-pod -- ping camera-ip

   # Verify credentials
   kubectl get secret camera-credentials -o yaml
   ```

2. **MQTT Publishing Issues**

   ```bash
   # Check broker connectivity
   kubectl exec -it media-connector-pod -- mosquitto_pub -h aio-broker -t test -m "hello"

   # Verify topic permissions
   kubectl get brokerlistener -n azure-iot-operations
   ```

3. **Storage Issues**

   ```bash
   # Check storage class
   kubectl get storageclass

   # Verify persistent volume claims
   kubectl get pvc -n azure-iot-operations
   ```

### Performance Tuning

| Parameter                | Description                       | Recommended Value |
|--------------------------|-----------------------------------|-------------------|
| `cpu_request`            | CPU resource request              | `100m`            |
| `cpu_limit`              | CPU resource limit                | `500m`            |
| `memory_request`         | Memory resource request           | `256Mi`           |
| `memory_limit`           | Memory resource limit             | `1Gi`             |
| `storage_request`        | Storage request for clips         | `10Gi`            |
| `max_concurrent_streams` | Maximum concurrent camera streams | `10`              |

## Security Considerations

- **Credential Management**: Use Kubernetes secrets for camera authentication
- **Network Security**: Implement network policies to restrict media connector access
- **Data Encryption**: Enable encryption at rest for stored media files
- **Access Control**: Use Azure RBAC for device and asset management
- **Audit Logging**: Enable comprehensive logging for security monitoring

## Integration Examples

### AI/ML Pipeline Integration

```python
# Example: Connect to media connector MQTT stream
import paho.mqtt.client as mqtt
import json
import base64
from PIL import Image

def on_message(client, userdata, message):
    data = json.loads(message.payload.decode())
    image_data = base64.b64decode(data['image'])

    # Process image with AI model
    image = Image.open(io.BytesIO(image_data))
    result = ai_model.predict(image)

    # Publish results
    client.publish("ai/results", json.dumps(result))

client = mqtt.Client()
client.on_message = on_message
client.connect("aio-broker", 1883, 60)
client.subscribe("media/snapshots/+")
client.loop_forever()
```

### Alert System Integration

Integrate with custom alert systems by processing MQTT messages from the media connector and triggering actions based on video analytics results.

#### Example: Motion Detection Alert Workflow

1. **AI/ML workload** subscribes to media connector snapshot MQTT topic
2. **Video analytics** processes images and publishes motion detection scores
3. **Alert handler** subscribes to analytics results and triggers actions

```python
# Example: Alert handler for motion detection
import paho.mqtt.client as mqtt
import json
import subprocess
from datetime import datetime

def on_analytics_result(client, userdata, message):
    """Process video analytics results and trigger alerts"""
    data = json.loads(message.payload.decode())

    if data.get('motion_score', 0) > 0.8:
        camera_id = data.get('camera_id')
        timestamp = datetime.now().isoformat()

        # Trigger video clip recording via MQTT command
        clip_command = {
            'camera_id': camera_id,
            'action': 'record_clip',
            'duration': 60,
            'timestamp': timestamp
        }
        client.publish('media/commands/clip', json.dumps(clip_command))

        # Send notification to Teams webhook
        teams_webhook = 'https://your-org.webhook.office.com/...'
        notification = {
            'text': f'Motion detected on {camera_id} at {timestamp}',
            'sections': [{
                'activityTitle': 'Security Alert',
                'activitySubtitle': f'Camera: {camera_id}',
                'facts': [
                    {'name': 'Motion Score', 'value': str(data['motion_score'])},
                    {'name': 'Timestamp', 'value': timestamp}
                ]
            }]
        }
        subprocess.run(['curl', '-X', 'POST', '-H', 'Content-Type: application/json',
                       '-d', json.dumps(notification), teams_webhook])

# Connect to MQTT broker
client = mqtt.Client()
client.on_message = on_analytics_result
client.connect("aio-broker", 1883, 60)
client.subscribe("analytics/motion/+")
client.loop_forever()
```

#### Kubernetes Deployment Example

Deploy the alert handler as a Kubernetes workload in the same namespace:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: media-alert-handler
  namespace: azure-iot-operations
spec:
  replicas: 1
  selector:
    matchLabels:
      app: media-alert-handler
  template:
    metadata:
      labels:
        app: media-alert-handler
    spec:
      containers:
      - name: alert-handler
        image: your-registry/media-alert-handler:latest
        env:
        - name: MQTT_BROKER
          value: "aio-broker:1883"
        - name: TEAMS_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: alert-config
              key: teams_webhook_url
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: alert-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alert-config
  namespace: azure-iot-operations
data:
  alert_rules.yaml: |
    # Alert configuration
    motion_detection:
      threshold: 0.8
      clip_duration: 60
      cooldown_period: 300

    cameras:
      - id: ip-camera-001
        enabled: true
        sensitivity: high
      - id: ip-camera-002
        enabled: true
        sensitivity: medium
---
apiVersion: v1
kind: Secret
metadata:
  name: alert-config
  namespace: azure-iot-operations
type: Opaque
stringData:
  teams_webhook_url: "https://your-org.webhook.office.com/..."
```

This example shows how to:

- Process MQTT messages from media connector and analytics workloads
- Trigger clip recording via MQTT commands to media connector
- Send notifications to external systems (Teams, email, etc.)
- Use ConfigMaps for alert rules configuration
- Use Secrets for webhook URLs and credentials

## Contributing

When contributing to this component:

1. Follow the established directory structure for 500-application components
2. Update documentation for any configuration changes
3. Test locally with Docker Compose before production deployment
4. Validate against Azure IoT Operations compatibility
5. Include example configurations for new features

Please see [CONTRIBUTING.md](../../../CONTRIBUTING.md) for general guidelines on contributing to this project.

## References

### Azure IoT Operations

- [Azure IoT Operations Media Connector Overview](https://learn.microsoft.com/en-us/azure/iot-operations/discover-manage-assets/overview-media-connector)
- [How to use the Media Connector](https://learn.microsoft.com/en-us/azure/iot-operations/discover-manage-assets/howto-use-media-connector)
- [Azure Container Storage for Arc](https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/overview)
- [Azure IoT Operations MQTT Broker](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/overview-dataflow)

### Monitoring and Observability

- [Azure Managed Grafana](https://learn.microsoft.com/en-us/azure/managed-grafana/overview)
- [Azure Monitor for Kubernetes](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable)
- [Container Insights for Arc-enabled Kubernetes](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-arc-enabled-clusters)
- [Prometheus Metrics in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-overview)

---

*AI and automation capabilities described in this component should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
