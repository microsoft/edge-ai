---
title: Akri ONVIF Connector
description: Complete standalone development and demo environment for integrating ONVIF-compliant IP cameras with Azure IoT Operations using the Akri connector framework
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
estimated_reading_time: 10
keywords:
  - azure iot operations
  - akri connector
  - onvif connector
  - ip camera
  - video surveillance
  - ptz control
  - edge computing
  - docker compose
  - terraform
  - profile s
  - profile t
---

## ONVIF Protocol Overview

### Akri ONVIF Connector

The Akri ONVIF Connector provides a complete, standalone development and testing environment
for integrating ONVIF-compliant IP cameras with Azure IoT Operations. This component
demonstrates how to use the Akri connector framework to discover, connect to, and manage ONVIF
cameras as assets in the Azure IoT Operations ecosystem.

This application component provides two deployment modes:

1. **Local Development Environment**: Docker Compose setup for development, testing, and demonstration
2. **Production Deployment (Terraform)**: ⚠️ **RECOMMENDED** - Use Terraform-based deployment via blueprints

The connector enables Azure IoT Operations to discover ONVIF camera capabilities, subscribe to
camera events (motion detection, tampering), control PTZ (Pan-Tilt-Zoom) operations, and retrieve
media stream URIs for video analytics workloads.

> **💡 RECOMMENDED APPROACH**: For production deployments, use the Terraform-based configuration in
> the `full-single-node-cluster` blueprint with the `onvif-connector-assets.tfvars.example` file as a
> reference for configuring your ONVIF connector assets.

## What is ONVIF?

ONVIF (Open Network Video Interface Forum) is an international open industry standard for IP-based
physical security products, including network video devices like IP cameras, NVRs, and video
management systems. ONVIF provides standardized interfaces for device discovery, configuration,
streaming, and event management.

### ONVIF Profiles

This implementation supports:

- **Profile S**: IP video systems including video streaming, PTZ control, audio, and basic analytics
  - H.264 video encoding
  - JPEG snapshot support
  - PTZ control
  - Event handling
  - Basic imaging settings

- **Profile T**: Advanced video streaming for modern IP cameras
  - H.265 (HEVC) video encoding
  - 4K resolution support
  - Enhanced metadata
  - Advanced streaming capabilities

## Use Case: ONVIF Camera Integration for Edge AI

This implementation demonstrates industrial video surveillance integration with:

- **Device Discovery**: Automatic detection of ONVIF camera capabilities
- **Media Profiles**: H.264, JPEG, and H.265 stream configuration
- **PTZ Control**: Remote pan, tilt, and zoom via MQTT commands
- **Event Monitoring**: Real-time motion detection and tampering alerts
- **Stream URIs**: Media endpoints for video analytics pipelines

### ONVIF Services Supported

The ONVIF camera simulator implements the following ONVIF services:

- **Device Service**: Device information, capabilities, system date/time
- **Media Service**: Media profiles, stream URIs, video source configuration
- **PTZ Service**: Pan, tilt, zoom control, position queries, movement commands
- **Event Service**: Event subscription, pull messages for motion/tampering events
- **Imaging Service**: Brightness, contrast, saturation, focus settings

## Local Development Architecture

The Docker Compose environment simulates a complete ONVIF integration ecosystem:

- **MQTT Broker**: Local Mosquitto broker for command/event routing
- **ONVIF Camera Simulator**: Simulated IP camera with Profile S/T support
- **ONVIF Connector Client**: Discovers devices, subscribes to events, handles PTZ commands
- **MQTT Monitor**: Real-time message monitoring for debugging

```text
┌─────────────────────┐
│  ONVIF Camera       │◄──── SOAP/XML ────┐
│  Simulator          │                    │
│  (Port 8080)        │                    │
│  - Profile S (H.264)│                    │
│  - Profile T (H.265)│                    │
│  - PTZ Control      │                    │
│  - Events           │                    │
└─────────────────────┘                    │
                                           │
┌─────────────────────┐                    │
│  MQTT Broker        │◄────┐              │
│  (Port 11883)       │     │              │
│  Topics:            │     │              │
│  - camera/ptz/cmd   │     │              │
│  - camera/events/*  │     │              │
└─────────────────────┘     │              │
         ▲                  │              │
         │                  │              │
         └──────┬───────────┘              │
                │                          │
┌───────────────▼─────────┐                │
│  ONVIF Connector        │────────────────┘
│  Client                 │
│  - Device Discovery     │
│  - Event Subscription   │
│  - PTZ Commands         │
│  - MQTT Publishing      │
└─────────────────────────┘
```

## Azure IoT Operations Integration

For Azure IoT Operations deployments, the component uses:

- **Connector Templates**: Deployed via the `110-iot-ops` component's `akri-connectors` module
- **Device Endpoints**: Kubernetes resources defining ONVIF camera endpoints
- **Asset Definitions**: Resources configuring PTZ control, events, and media URIs
- **Event Streaming**: Real-time event forwarding to MQTT topics
- **Command Handling**: PTZ commands via MQTT command topics

## Deployment Prerequisites

### Local Development

- **Docker**: Version 20.10+ with Docker Compose support
- **curl**: For testing ONVIF endpoints
- **mosquitto-clients** (optional): For MQTT testing with `mosquitto_sub`/`mosquitto_pub`

### Azure IoT Operations Integration (Terraform - Recommended)

- **Blueprint Deployment**: Use `full-single-node-cluster` blueprint with ONVIF connector variables
- **Terraform**: Version 1.9.8 or later

## Getting Started with Local Development

### Starting the Environment

```bash
docker compose up -d
- **Azure Subscription**: Active subscription with appropriate permissions
- **Example Configuration**: Reference `blueprints/full-single-node-cluster/terraform/onvif-connector-assets.tfvars.example`

## Quick Start

### 1. Local Development Environment Setup

Start the complete local development environment:

```bash
# Navigate to the component directory
cd src/500-application/510-onvif-connector

# Copy environment configuration
cp .env.example .env

# (Optional) Edit .env to customize settings
nano .env

# Start all services
docker compose up -d

# View service status
docker compose ps

# View logs
docker compose logs -f

# Stop the environment
docker compose down
```bash

### Viewing Logs

```bash
# All services
```bash

### 2. Verify ONVIF Camera Simulator

Test the ONVIF camera endpoints:

```bash
# Check health endpoint
curl http://localhost:8080/health

# Get device information (SOAP request)
curl -X POST http://localhost:8080/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
    <tds:GetDeviceInformation/>
  </s:Body>
</s:Envelope>'
```text

Expected response includes manufacturer, model, firmware version, and serial number.

### 3. Monitor ONVIF Connector Discovery

Watch the connector discover camera capabilities:

```bash
# View connector logs showing discovery process
docker logs onvif-mqtt-monitor -f
```bash

## Testing ONVIF Capabilities

### Device Information

```bash
curl http://localhost:8080/health
```text

Expected output:

```text
INFO - Connecting to ONVIF device: http://onvif-camera-simulator:8080/onvif/device_service
INFO - Device discovered: {'manufacturer': 'Edge AI Simulator', 'model': 'ONVIF-PTZ-4K', 'firmware': '1.0.0', 'serial': '77200454'}
INFO - Capabilities discovered: {'media': True, 'ptz': True, 'events': True, 'imaging': True}
INFO - Media profiles discovered: 3 profiles
INFO -   - Profile S - H.264 Main Stream (token: profile_s_h264)
INFO -   - Profile S - JPEG Snapshots (token: profile_s_jpeg)
INFO -   - Profile T - H.265 4K Stream (token: profile_t_h265)
INFO - ONVIF device discovery completed successfully
INFO - Starting event subscription loop (interval: 5s)
```bash

### 4. Monitor MQTT Events

Watch camera events being published to MQTT:

```bash
# Subscribe to all ONVIF camera events
docker exec -it onvif-mqtt-monitor mosquitto_sub -h onvif-mosquitto-broker -p 11883 -t 'onvif-camera/#' -v

# Subscribe to motion events only
docker exec -it onvif-mqtt-monitor mosquitto_sub -h onvif-mosquitto-broker -p 11883 -t 'onvif-camera/events/motion' -v

# Subscribe to tampering events
docker exec -it onvif-mqtt-monitor mosquitto_sub -h onvif-mosquitto-broker -p 11883 -t 'onvif-camera/events/tampering' -v
```text

Expected MQTT messages:

```text
onvif-camera/events/motion {"type": "motion", "detected": true, "timestamp": 1705339200000}
onvif-camera/events/tampering {"type": "tampering", "detected": false, "timestamp": 1705339205000}
```bash

### 5. Send PTZ Commands

Control camera pan, tilt, and zoom via MQTT:

```bash
# Pan right
docker exec -it onvif-mqtt-monitor mosquitto_pub -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/pan' -m '{"direction": "right", "speed": 0.5}'

# Tilt up
docker exec -it onvif-mqtt-monitor mosquitto_pub -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/tilt' -m '{"direction": "up", "speed": 0.5}'

# Zoom in
docker exec -it onvif-mqtt-monitor mosquitto_pub -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/zoom' -m '{"direction": "in", "speed": 0.3}'

# Move to home position
docker exec -it onvif-mqtt-monitor mosquitto_pub -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/home' -m '{}'
```bash

### 6. View Connector Statistics

```bash
# Check connector statistics
docker logs onvif-connector-client | grep "Statistics"
```text

Expected output:

```text
INFO - Statistics: {'events_received': 25, 'events_published': 25, 'ptz_commands': 4, 'connection_attempts': 1, 'last_event_time': 1705339250000}
```bash

## Production Deployment Using Terraform

**RECOMMENDED** - Deploy ONVIF connector assets using Infrastructure as Code:

### Setup Prerequisites

1. Deploy the `full-single-node-cluster` blueprint (or another blueprint with IoT Operations)
2. Ensure ONVIF cameras are accessible from the cluster network
3. Configure camera credentials if authentication is required

### Terraform Configuration

Create or modify `onvif-connector-assets.tfvars` in the blueprint:

```bash
cd blueprints/full-single-node-cluster/terraform

# Copy example configuration
cp onvif-connector-assets.tfvars.example onvif-connector-assets.tfvars

# Edit configuration to match your ONVIF cameras
nano onvif-connector-assets.tfvars
```text

Example configuration:

```hcl
onvif_connector_devices = [
  {
    name        = "warehouse-camera-01"
    description = "Warehouse entrance PTZ camera"
    endpoint    = "http://192.168.1.100/onvif/device_service"
    username    = "admin"  # Optional
    password    = "secure-password"  # Optional

    assets = [
      {
        name        = "warehouse-ptz-control"
        description = "PTZ control for warehouse camera"

        management_groups = [
          {
            name = "ptz_controls"
            actions = [
              {
                name        = "pan_right"
                action_type = "Call"
                target_uri  = "http://192.168.1.100/onvif/ptz_service"
                topic       = "cameras/warehouse/ptz/pan"
                action_configuration = jsonencode({direction = "right", speed = 0.5})
              },
              {
                name        = "tilt_up"
                action_type = "Call"
                target_uri  = "http://192.168.1.100/onvif/ptz_service"
                topic       = "cameras/warehouse/ptz/tilt"
                action_configuration = jsonencode({direction = "up", speed = 0.5})
              }
            ]
          }
        ]

        event_groups = [
          {
            name = "motion_events"
            events = [
              {
                name        = "MOTION_DETECTED"
                data_source = "onvif://motion_detection"
                destinations = [
                  {
                    target = "Mqtt"
                    configuration = {
                      topic = "cameras/warehouse/events/motion"
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
]
```bash

### Deploy

```bash
# Preview changes
terraform plan -var-file="onvif-connector-assets.tfvars"

# Apply configuration
terraform apply -var-file="onvif-connector-assets.tfvars"
```bash

### Verify

```bash
# Check deployed devices and assets
kubectl get devices,assets -n azure-iot-operations

# Check connector instances
kubectl get connectorinstance,connectortemplate -n azure-iot-operations

# View connector logs
kubectl logs -l app.kubernetes.io/name=onvif-connector -n azure-iot-operations --tail=100 -f

# Monitor MQTT messages
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  sh -c "mosquitto_sub --host aio-broker.azure-iot-operations --port 18883 \
         --username 'K8S-SAT' --pw \$(cat /var/run/secrets/tokens/broker-sat) \
         --cafile /var/run/certs/ca.crt --topic 'cameras/#' -v"

# Send PTZ command
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  sh -c "mosquitto_pub --host aio-broker.azure-iot-operations --port 18883 \
         --username 'K8S-SAT' --pw \$(cat /var/run/secrets/tokens/broker-sat) \
         --cafile /var/run/certs/ca.crt \
         --topic 'cameras/warehouse/ptz/pan' \
         --message '{\"direction\": \"right\", \"speed\": 0.5}'"
```text

**Configuration Reference**: See `blueprints/full-single-node-cluster/terraform/onvif-connector-assets.tfvars.example`
for a complete example of all available configuration options.

## ONVIF vs RTSP vs REST Connectors

Understanding when to use different camera integration approaches:

| Feature              | ONVIF Connector                | RTSP Connector               | REST Connector       |
|----------------------|--------------------------------|------------------------------|----------------------|
| **Protocol**         | SOAP/XML over HTTP             | Real-Time Streaming Protocol | HTTP REST/JSON       |
| **Standard**         | ONVIF (open industry standard) | IETF RFC 7826                | Vendor-specific      |
| **Discovery**        | GetCapabilities, GetProfiles   | Manual configuration         | Manual configuration |
| **Video Streaming**  | Via GetStreamUri (RTSP/HTTP)   | Native protocol              | Not supported        |
| **PTZ Control**      | Native SOAP commands           | Via RTSP extensions          | Vendor REST APIs     |
| **Events**           | Pull messages pattern          | Not supported                | Polling or webhooks  |
| **Device Info**      | Standardized metadata          | Limited                      | Vendor-specific      |
| **Interoperability** | High (ONVIF certified)         | Medium                       | Low (vendor lock-in) |
| **Use Case**         | Standard IP cameras            | Video streaming only         | Custom camera APIs   |

### When to Use ONVIF Connector

- ONVIF-certified IP cameras (most modern cameras)
- Standardized camera discovery and control
- PTZ control requirements
- Event-driven monitoring (motion, tampering)
- Multi-vendor camera deployments
- Need for device capabilities introspection

### When to Use RTSP Connector

- Pure video streaming workloads
- No control or event requirements
- Legacy cameras with RTSP support only
- High-performance streaming needs

### When to Use REST Connector

- Vendor-specific camera APIs
- Custom integration requirements
- Cameras without ONVIF/RTSP support
- Proprietary device features

## Architecture Details

### ONVIF Camera Simulator (`services/onvif-camera-simulator/`)

Python-based SOAP/XML server implementing ONVIF specifications:

**Media Profiles**:

```python
Profile S - H.264 Main Stream:
  - Token: profile_s_h264
  - Encoding: H.264
  - Resolution: 1920x1080 (1080p)
  - Frame Rate: 30 fps
  - Bitrate: 4096 kbps

Profile S - JPEG Snapshots:
  - Token: profile_s_jpeg
  - Encoding: JPEG
  - Resolution: 1920x1080
  - Quality: 95

Profile T - H.265 4K Stream:
  - Token: profile_t_h265
  - Encoding: H.265 (HEVC)
  - Resolution: 3840x2160 (4K)
  - Frame Rate: 30 fps
  - Bitrate: 8192 kbps
```text

**ONVIF Services Implemented**:

- `/onvif/device_service`: Device information, capabilities, system date/time
- `/onvif/media_service`: Media profiles, stream URIs, video source configuration
- `/onvif/ptz_service`: PTZ control, position queries, movement commands
- `/onvif/event_service`: Event subscription, pull messages
- `/onvif/imaging_service`: Imaging settings (brightness, contrast, etc.)

**Environment Variables**:

- `ONVIF_PORT`: HTTP server port (default: 8080)
- `ONVIF_DEVICE_ID`: Device identifier (default: onvif-camera-001)
- `ONVIF_MANUFACTURER`: Device manufacturer (default: Edge AI Simulator)
- `ONVIF_MODEL`: Device model (default: ONVIF-PTZ-4K)
- `ONVIF_FIRMWARE`: Firmware version (default: 1.0.0)
- `ONVIF_SERIAL`: Serial number (default: random UUID)

### ONVIF Connector Client (`services/onvif-connector-client/`)

Python client implementing ONVIF device discovery and integration:

**Discovery Workflow**:

```python
1. Connect to ONVIF device endpoint
2. GetDeviceInformation() → Manufacturer, model, firmware, serial
3. GetCapabilities() → Supported services (media, PTZ, events, imaging)
4. GetProfiles() → Available media profiles (H.264, JPEG, H.265)
5. Subscribe to events (motion, tampering) via PullMessages
6. Listen for PTZ commands on MQTT topics
7. Publish events to MQTT as they occur
```text

**Environment Variables**:

- `ONVIF_DEVICE_ID`: Target device identifier
- `ONVIF_HOST`: ONVIF camera hostname
- `ONVIF_PORT`: ONVIF camera port (default: 8080)
- `ONVIF_USERNAME`: Authentication username (optional)
- `ONVIF_PASSWORD`: Authentication password (optional)
- `MQTT_BROKER`: MQTT broker hostname
- `MQTT_PORT`: MQTT broker port
- `MQTT_TOPIC_PREFIX`: Topic prefix for events (default: onvif-camera)
- `EVENT_POLL_INTERVAL`: Event polling interval in seconds (default: 5)
- `PTZ_PAN_SPEED`: Pan speed 0.0-1.0 (default: 0.5)
- `PTZ_TILT_SPEED`: Tilt speed 0.0-1.0 (default: 0.5)
- `PTZ_ZOOM_SPEED`: Zoom speed 0.0-1.0 (default: 0.3)
- `DEBUG_MODE`: Enable debug logging (default: false)
- `LOG_LEVEL`: Logging level (default: INFO)

### PTZ Command Mapping

The connector listens on MQTT command topics and translates them to ONVIF SOAP requests:

```text
MQTT Topic                     → ONVIF Command
─────────────────────────────────────────────────────────────
onvif-camera/ptz/command/pan   → RelativeMove (Pan axis)
onvif-camera/ptz/command/tilt  → RelativeMove (Tilt axis)
onvif-camera/ptz/command/zoom  → RelativeMove (Zoom axis)
onvif-camera/ptz/command/home  → GotoHomePosition
```bash

### Event to Topic Mapping

Camera events are published to MQTT topics:

```text
ONVIF Event        → MQTT Topic                    → Payload
─────────────────────────────────────────────────────────────────────
Motion Detected    → onvif-camera/events/motion    → {"type": "motion", "detected": true, ...}
Tampering Alert    → onvif-camera/events/tampering → {"type": "tampering", "detected": true, ...}
```bash

## Troubleshooting

### ONVIF Camera Simulator Not Starting

```bash
# Check container status
docker ps -a | grep onvif-camera-simulator

# View logs
docker logs onvif-camera-simulator

# Verify port availability
lsof -i :8080  # Should be free or used by onvif-camera-simulator

# Test health endpoint
curl http://localhost:8080/health
```bash

### Connector Client Discovery Failures

```bash
# Check connector logs
docker logs onvif-connector-client

# Test ONVIF endpoint manually
curl -X POST http://localhost:8080/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
    <tds:GetDeviceInformation/>
  </s:Body>
</s:Envelope>'

# Verify network connectivity
docker exec onvif-connector-client ping -c 3 onvif-camera-simulator
```bash

### No Events Received

```bash
# Check event polling in connector logs
docker logs onvif-connector-client | grep "event"

# Verify MQTT broker connectivity
docker logs onvif-mosquitto-broker

# Subscribe to all topics
docker exec -it onvif-mqtt-monitor mosquitto_sub -h onvif-mosquitto-broker -p 11883 -t '#' -v
```bash

### PTZ Commands Not Working

```bash
# Check connector PTZ subscription
docker logs onvif-connector-client | grep "PTZ"

# Test command publishing
docker exec -it onvif-mqtt-monitor mosquitto_pub \
  -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/pan' \
  -m '{"direction": "right", "speed": 0.5}'

# Verify command reception in connector logs
docker logs onvif-connector-client --tail 20
```bash

### Production Deployment Issues

```bash
# Check connector pod status
kubectl get pods -n azure-iot-operations | grep onvif-connector

# View connector logs
kubectl logs -l app.kubernetes.io/name=onvif-connector -n azure-iot-operations --tail=100

# Check device and asset status
kubectl describe device warehouse-camera-01 -n azure-iot-operations
kubectl describe asset warehouse-ptz-control -n azure-iot-operations

# Verify ONVIF endpoint accessibility from cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -X POST http://your-camera-ip/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body xmlns:tds="http://www.onvif.org/ver10/device/wsdl"><tds:GetDeviceInformation/></s:Body></s:Envelope>'
```bash

## Development and Customization

### Adding New ONVIF Services

1. Add service endpoint to camera simulator:

```python
# In services/onvif-camera-simulator/onvif_camera.py
async def handle_analytics_service(self, request):
    body = await request.text()
    # Parse SOAP request
    # Generate SOAP response
    return web.Response(text=response, content_type='application/soap+xml')
```text

2. Register route:

```python
app.router.add_post('/onvif/analytics_service', camera.handle_analytics_service)
```text

3. Update connector client to use new service.

### Custom Event Types

To add custom camera events:

1. Modify camera simulator event generation:

```python
# In onvif_camera.py
event_data = {
    'type': 'custom_event',
    'timestamp': timestamp,
    'custom_field': 'value'
}
```text

2. Update connector event parsing:

```python
# In onvif_connector.py
if event_type == 'custom_event':
    topic = f"{self.mqtt_topic_prefix}/events/custom"
    await self._publish_event(topic, event_data)
```bash

### Performance Tuning

**Event Polling**:

- `EVENT_POLL_INTERVAL`: Reduce for faster event detection (increases load)
- Use event push mechanisms if camera supports (WS-BaseNotification)

**PTZ Control**:

- Adjust `PTZ_*_SPEED` values for your camera's capabilities
- Implement PTZ presets for common positions
- Add position feedback for closed-loop control

**Connection Pooling**:

- For multiple cameras, use connection pools
- Implement retry logic with exponential backoff
- Configure timeout values appropriately

## Security Considerations

### Authentication

The ONVIF connector supports:

- **Anonymous**: No authentication (development only)
- **HTTP Digest Auth**: Username/password authentication
- **WS-UsernameToken**: SOAP-level authentication
- **TLS Client Certificates**: Certificate-based authentication (recommended)

### TLS/SSL

For production deployments:

1. Use HTTPS for ONVIF connections
2. Configure certificate validation
3. Implement mutual TLS (mTLS) where supported
4. Use TLS 1.2+ only

### Network Security

- Isolate camera VLANs from production networks
- Use Kubernetes network policies to restrict access
- Implement firewall rules for camera IP ranges
- Use VPN/tunneling for remote cameras

### Credential Management

- Store camera credentials in Kubernetes secrets
- Use Azure Key Vault for credential rotation
- Avoid hardcoded passwords in configuration
- Implement least-privilege access

## ONVIF Compliance and Standards

### Supported ONVIF Specifications

- **ONVIF Core Specification**: Version 21.06
- **Profile S**: Streaming video
- **Profile T**: Advanced video streaming
- **WS-Discovery**: Device discovery (not implemented in simulator)

### ONVIF Test Tool Validation

For production cameras, validate ONVIF compliance using:

- ONVIF Device Test Tool
- ONVIF Conformance Tool
- Camera manufacturer certification documents

### Known Limitations

- **WS-Discovery**: Not implemented (manual configuration required)
- **Event Push**: Uses pull messages pattern only
- **Audio**: Not implemented in simulator
- **Analytics**: Basic motion detection only
- **Recording**: Not supported (use separate VMS/NVR)

## Migration from Legacy Camera Integration

If migrating from legacy camera integration approaches:

### Key Differences

| Legacy                     | ONVIF Connector         |
|----------------------------|-------------------------|
| RTSP streams only          | Full ONVIF capabilities |
| Manual PTZ control scripts | Standard ONVIF PTZ      |
| Vendor-specific APIs       | Standard ONVIF API      |
| No event support           | Motion/tampering events |
| Static configuration       | Dynamic discovery       |

### Migration Steps

1. **Inventory** existing cameras and verify ONVIF support
2. **Test** ONVIF compliance using test tools
3. **Extract** camera credentials and network configuration
4. **Configure** `onvif-connector-assets.tfvars` with camera details
5. **Test** locally with Docker Compose (use simulator first)
6. **Deploy** via Terraform blueprint to staging
7. **Validate** discovery, events, and PTZ control
8. **Migrate** production cameras incrementally
9. **Archive** legacy integration scripts

## Related Documentation

### Azure IoT Operations

- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Azure IoT Operations Device Management](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-manage-assets)
- [Akri Connector Framework](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/concept-akri-architecture)

### ONVIF Standards

- [ONVIF Specifications](https://www.onvif.org/profiles/)
- [ONVIF Profile S](https://www.onvif.org/profiles/profile-s/)
- [ONVIF Profile T](https://www.onvif.org/profiles/profile-t/)

### Related Components

- [AI Inference Service](../507-ai-inference/README.md) - Production AI inference with MQTT integration
- [REST HTTP Connector](../505-akri-rest-http-connector/README.md) - REST-based device APIs
- [Blueprint Documentation](../../../blueprints/full-single-node-cluster/README.md) - Full deployment guide

## Contributing

When contributing to this component:

1. Follow the established directory structure for 500-application components
2. Update documentation for any configuration changes
3. Test locally with Docker Compose before production deployment
4. Validate against Azure IoT Operations compatibility
5. Include example configurations for new features

Please see [CONTRIBUTING.md](../../../CONTRIBUTING.md) for general guidelines on contributing to this project.

## Appendix: ONVIF SOAP Examples

### GetDeviceInformation Request

```xml
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
    <tds:GetDeviceInformation/>
  </s:Body>
</s:Envelope>
```bash

### GetDeviceInformation Response

```xml
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body>
    <tds:GetDeviceInformationResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
      <tds:Manufacturer>Edge AI Simulator</tds:Manufacturer>
      <tds:Model>ONVIF-PTZ-4K</tds:Model>
      <tds:FirmwareVersion>1.0.0</tds:FirmwareVersion>
      <tds:SerialNumber>77200454</tds:SerialNumber>
    </tds:GetDeviceInformationResponse>
  </s:Body>
</s:Envelope>
```bash

### GetProfiles Request

```xml
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:trt="http://www.onvif.org/ver10/media/wsdl">
    <trt:GetProfiles/>
  </s:Body>
</s:Envelope>
```bash

### RelativeMove PTZ Request

```xml
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
    <tptz:RelativeMove>
      <tptz:ProfileToken>profile_s_h264</tptz:ProfileToken>
      <tptz:Translation>
        <tt:PanTilt x="0.5" y="0.0" space="http://www.onvif.org/ver10/tptz/PanTiltSpaces/TranslationGenericSpace"/>
        <tt:Zoom x="0.0" space="http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace"/>
      </tptz:Translation>
      <tptz:Speed>
        <tt:PanTilt x="0.5" y="0.5" space="http://www.onvif.org/ver10/tptz/PanTiltSpaces/GenericSpeedSpace"/>
        <tt:Zoom x="0.3" space="http://www.onvif.org/ver10/tptz/ZoomSpaces/ZoomGenericSpeedSpace"/>
      </tptz:Speed>
    </tptz:RelativeMove>
  </s:Body>
</s:Envelope>
```bash

### PullMessages Event Request

```xml
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body xmlns:tev="http://www.onvif.org/ver10/events/wsdl">
    <tev:PullMessages>
      <tev:Timeout>PT5S</tev:Timeout>
      <tev:MessageLimit>10</tev:MessageLimit>
    </tev:PullMessages>
  </s:Body>
</s:Envelope>
```bash

## Appendix: Media Profile Examples

### Profile S - H.264 Stream

```json
{
  "token": "profile_s_h264",
  "name": "Profile S - H.264 Main Stream",
  "video_encoder": {
    "encoding": "H264",
    "resolution": {
      "width": 1920,
      "height": 1080
    },
    "quality": 4.0,
    "frame_rate": 30,
    "bitrate": 4096
  },
  "stream_uri": "rtsp://onvif-camera-simulator:554/stream/profile_s_h264"
}
```bash

### Profile T - H.265 4K Stream

```json
{
  "token": "profile_t_h265",
  "name": "Profile T - H.265 4K Stream",
  "video_encoder": {
    "encoding": "H265",
    "resolution": {
      "width": 3840,
      "height": 2160
    },
    "quality": 5.0,
    "frame_rate": 30,
    "bitrate": 8192
  },
    "stream_uri": "rtsp://onvif-camera-simulator:554/stream/profile_t_h265"
}
```

---

*AI and automation capabilities described in this component should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
