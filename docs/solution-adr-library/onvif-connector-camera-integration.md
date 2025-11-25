---
title: ONVIF Connector for IP Camera Integration
description: Architecture Decision Record for implementing ONVIF (Open Network Video Interface Forum) connector in Azure IoT Operations to enable standardized IP camera integration. Addresses device discovery, PTZ control, event monitoring, and media stream management for ONVIF-compliant cameras in edge computing environments.
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: architecture-decision-record
estimated_reading_time: 10
keywords:
  - onvif-connector
  - ip-camera
  - akri-connector
  - ptz-control
  - azure-iot-operations
  - video-surveillance
  - profile-s
  - profile-t
  - edge-computing
  - mqtt-broker
  - camera-events
  - motion-detection
  - adr
---

## Status

- [ ] Draft
- [X] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

Industrial IoT and edge AI deployments increasingly rely on IP cameras for video analytics,
surveillance, and monitoring applications. These cameras generate events (motion detection,
tampering alerts), require control interfaces (PTZ operations), and produce media streams
for real-time and batch processing.

The lack of standardization in camera APIs creates vendor lock-in, complex integration
requirements, and maintenance challenges when managing multi-vendor camera deployments
across edge locations.

ONVIF (Open Network Video Interface Forum) is an internationally recognized open standard
for IP-based physical security products, providing standardized interfaces for:

- Device discovery and capability introspection
- Media stream configuration and retrieval
- PTZ (Pan-Tilt-Zoom) control
- Event subscription and notification
- Imaging and analytics configuration

## Decision

Implement an Akri ONVIF Connector for Azure IoT Operations that:

1. Discovers ONVIF-compliant cameras and their capabilities
2. Subscribes to camera events (motion, tampering) via SOAP PullMessages
3. Controls PTZ operations via MQTT command topics
4. Retrieves media profile configurations and stream URIs
5. Publishes events to MQTT for downstream processing
6. Supports ONVIF Profile S and Profile T specifications
7. Provides local development environment with camera simulator

## Decision Drivers

- **Standardization**: ONVIF is the industry-standard protocol for IP cameras
- **Interoperability**: Multi-vendor camera support without custom integrations
- **Capability Discovery**: Automatic detection of camera features (PTZ, events, analytics)
- **Event-Driven**: Real-time motion detection and tampering alerts
- **Control Interface**: Standardized PTZ commands for camera positioning
- **Media Access**: Structured access to H.264, H.265, and JPEG streams
- **Edge Compatibility**: SOAP/XML over HTTP works in constrained networks

## Considered Options

### Option A: RTSP Streaming Only

**Pros:**

- Simple video streaming protocol
- Low overhead for media transport
- Widely supported by cameras
- Good for pure streaming use cases

**Cons:**

- No standardized device discovery
- Limited control interfaces (vendor-specific extensions)
- No event notification mechanism
- No capability introspection
- Requires manual configuration for each camera model

### Option B: Vendor-Specific REST APIs

**Pros:**

- Modern HTTP/JSON interfaces
- Potentially richer feature sets
- Easier to test with standard tools

**Cons:**

- Vendor lock-in (different API per manufacturer)
- No interoperability guarantees
- Fragmented documentation
- Maintenance burden for multi-vendor deployments
- Custom code per camera model

### Option C: ONVIF Connector (Selected)

**Pros:**

- Industry-standard protocol (ONVIF certified cameras)
- Multi-vendor interoperability
- Standardized discovery and capability detection
- Native PTZ control
- Event subscription (motion, tampering, analytics)
- Media profile enumeration
- Profile S and T support (H.264, H.265, 4K)

**Cons:**

- SOAP/XML overhead vs REST/JSON
- Complex ONVIF specification
- Requires ONVIF-certified cameras
- Pull-based event model (polling)

### Option D: Custom Camera Integration Framework

**Pros:**

- Maximum flexibility
- Optimized for specific use cases
- Custom protocol design

**Cons:**

- Significant development effort
- No ecosystem support
- Compatibility burden
- Non-standard approach

## Decision Conclusion

The ONVIF Connector was selected as the optimal solution for IP camera integration in
Azure IoT Operations edge environments, providing standardized access to camera capabilities
while maintaining vendor independence.

### Architecture

The ONVIF Connector architecture consists of:

```plaintext
┌─────────────────────────────┐
│  ONVIF IP Camera            │
│  (Profile S/T Certified)    │
│                             │
│  Services:                  │
│  - Device (capabilities)    │
│  - Media (streams/profiles) │
│  - PTZ (control)            │
│  - Events (motion/tampering)│
│  - Imaging (settings)       │
└──────────────┬──────────────┘
               │ SOAP/XML over HTTP
               │
               ▼
┌─────────────────────────────┐
│  Akri ONVIF Connector       │
│                             │
│  Discovery:                 │
│  - GetDeviceInformation     │
│  - GetCapabilities          │
│  - GetProfiles              │
│                             │
│  Operations:                │
│  - PullMessages (events)    │
│  - RelativeMove (PTZ)       │
│  - GetStreamUri (media)     │
└──────────────┬──────────────┘
               │
               ├──► MQTT (Events)
               │    - motion detection
               │    - tampering alerts
               │
               └──► MQTT (PTZ Commands)
                    - pan/tilt/zoom
                    - home position
```

### Component Structure

```plaintext
src/500-application/510-onvif-connector/
├── services/
│   ├── onvif-camera-simulator/    # ONVIF camera simulator
│   │   ├── onvif_camera.py        # SOAP/XML server
│   │   └── Dockerfile
│   └── onvif-connector-client/    # Connector implementation
│       ├── onvif_connector.py     # Discovery + events + PTZ
│       └── Dockerfile
├── docker-compose.yml              # Local dev environment
└── README.md                       # Complete documentation
```

### ONVIF Services Implementation

The connector implements the following ONVIF services:

**Device Service** (`/onvif/device_service`):

- `GetDeviceInformation`: Manufacturer, model, firmware, serial
- `GetCapabilities`: Supported services (media, PTZ, events, imaging)
- `GetSystemDateAndTime`: Camera clock synchronization

**Media Service** (`/onvif/media_service`):

- `GetProfiles`: Available media profiles (H.264, JPEG, H.265)
- `GetStreamUri`: RTSP/HTTP URIs for video streams
- `GetVideoSourceConfiguration`: Resolution, frame rate, bitrate

**PTZ Service** (`/onvif/ptz_service`):

- `RelativeMove`: Pan, tilt, zoom relative to current position
- `GetStatus`: Current PTZ position
- `GotoHomePosition`: Return to preset home position

**Event Service** (`/onvif/event_service`):

- `PullMessages`: Poll for motion/tampering events
- Event types: motion detection, tampering alerts

**Imaging Service** (`/onvif/imaging_service`):

- `GetImagingSettings`: Brightness, contrast, saturation
- `SetImagingSettings`: Configure image parameters

### ONVIF Profiles Supported

**Profile S** - Standard IP Video Systems:

- H.264 video encoding (1080p)
- JPEG snapshot support
- PTZ control (pan, tilt, zoom)
- Event handling (motion, tampering)
- Basic imaging settings

**Profile T** - Advanced Video Streaming:

- H.265 (HEVC) encoding (4K)
- Enhanced metadata
- Advanced streaming capabilities
- Modern codec support

### Media Profile Examples

The simulator provides three media profiles:

```python
Profile S - H.264 Main Stream:
  - Token: profile_s_h264
  - Encoding: H.264
  - Resolution: 1920x1080 (1080p)
  - Frame Rate: 30 fps
  - Bitrate: 4096 kbps
  - Stream URI: rtsp://camera:554/stream/profile_s_h264

Profile S - JPEG Snapshots:
  - Token: profile_s_jpeg
  - Encoding: JPEG
  - Resolution: 1920x1080
  - Quality: 95
  - Stream URI: http://camera:80/snapshot/profile_s_jpeg

Profile T - H.265 4K Stream:
  - Token: profile_t_h265
  - Encoding: H.265 (HEVC)
  - Resolution: 3840x2160 (4K)
  - Frame Rate: 30 fps
  - Bitrate: 8192 kbps
  - Stream URI: rtsp://camera:554/stream/profile_t_h265
```

### Discovery Workflow

The connector executes the following discovery sequence:

```python
1. Connect to ONVIF endpoint
   → http://camera-ip/onvif/device_service

2. GetDeviceInformation()
   → Manufacturer: Edge AI Simulator
   → Model: ONVIF-PTZ-4K
   → Firmware: 1.0.0
   → Serial: 77200454

3. GetCapabilities()
   → Media: True
   → PTZ: True
   → Events: True
   → Imaging: True

4. GetProfiles()
   → Profile S (H.264): profile_s_h264
   → Profile S (JPEG): profile_s_jpeg
   → Profile T (H.265): profile_t_h265

5. Subscribe to Events
   → PullMessages every 5 seconds
   → Motion detection
   → Tampering alerts

6. Listen for PTZ Commands
   → MQTT topic: onvif-camera/ptz/command/#
   → Commands: pan, tilt, zoom, home
```

### Event Handling

The connector uses the ONVIF PullMessages pattern for events:

```xml
<!-- Request: Poll for events every 5 seconds -->
<tev:PullMessages>
  <tev:Timeout>PT5S</tev:Timeout>
  <tev:MessageLimit>10</tev:MessageLimit>
</tev:PullMessages>

<!-- Response: Motion detection event -->
<tev:NotificationMessage>
  <wsnt:Topic>tns1:RuleEngine/CellMotionDetector/Motion</wsnt:Topic>
  <wsnt:Message>
    <tt:Data>
      <tt:SimpleItem Name="State" Value="true"/>
    </tt:Data>
  </wsnt:Message>
</tev:NotificationMessage>
```

Events are published to MQTT:

```json
{
  "type": "motion",
  "detected": true,
  "timestamp": 1705339200000
}
```

### PTZ Control

PTZ commands are received via MQTT and translated to ONVIF SOAP:

```plaintext
MQTT Command:
  Topic: onvif-camera/ptz/command/pan
  Payload: {"direction": "right", "speed": 0.5}

ONVIF SOAP Request:
  <tptz:RelativeMove>
    <tptz:ProfileToken>profile_s_h264</tptz:ProfileToken>
    <tptz:Translation>
      <tt:PanTilt x="0.5" y="0.0"/>
      <tt:Zoom x="0.0"/>
    </tptz:Translation>
    <tptz:Speed>
      <tt:PanTilt x="0.5" y="0.5"/>
    </tptz:Speed>
  </tptz:RelativeMove>
```

Supported PTZ commands:

- **Pan**: `onvif-camera/ptz/command/pan` → Left/right movement
- **Tilt**: `onvif-camera/ptz/command/tilt` → Up/down movement
- **Zoom**: `onvif-camera/ptz/command/zoom` → In/out zoom
- **Home**: `onvif-camera/ptz/command/home` → Return to preset position

### Deployment Options

#### 1. Local Development (Docker Compose)

Quick start for testing and development:

```bash
cd src/500-application/510-onvif-connector
cp .env.example .env
docker compose up -d
```

Provides:

- ONVIF camera simulator (Profile S/T)
- Connector client
- MQTT broker
- MQTT monitor

Test PTZ commands:

```bash
docker exec -it onvif-mqtt-monitor mosquitto_pub \
  -h onvif-mosquitto-broker -p 11883 \
  -t 'onvif-camera/ptz/command/pan' \
  -m '{"direction": "right", "speed": 0.5}'
```

#### 2. Production Deployment (Terraform)

Blueprint-based deployment:

```bash
cd blueprints/full-single-node-cluster/terraform
terraform apply -var-file="onvif-connector-assets.tfvars"
```

Configuration example in `onvif-connector-assets.tfvars.example`:

```hcl
onvif_connector_devices = [
  {
    name        = "warehouse-camera-01"
    endpoint    = "https://192.168.1.100/onvif/device_service"
    # username    = "admin"
    # password    = "secure-password"

    assets = [
      {
        name = "warehouse-ptz-control"

        commands = [
          {
            name    = "pan_right"
            topic   = "cameras/warehouse/ptz/pan"
            payload = jsonencode({direction = "right", speed = 0.5})
          }
        ]

        events = [
          {
            name           = "MOTION_DETECTED"
            event_notifier = "motion"
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
```

### Integration with Akri Framework

The ONVIF Connector leverages the Akri connector module:

- **ConnectorTemplate**: Defines ONVIF endpoint type (`Microsoft.ONVIF`)
- **Device Registry**: Namespaced devices with ONVIF camera configurations
- **Asset Definitions**: PTZ commands and event subscriptions
- **MQTT Configuration**: Shared broker settings for events and commands

### Configuration Variables

Terraform variables in `src/100-edge/110-iot-ops/terraform/variables.akri.tf`:

```terraform
variable "should_enable_akri_onvif_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri ONVIF Connector template"
}

variable "onvif_connector_devices" {
  type = list(object({
    name        = string
    description = optional(string)
    endpoint    = string
    username    = optional(string)
    password    = optional(string)
    assets      = list(object({
      name        = string
      description = optional(string)
      commands    = optional(list(object({
        name    = string
        topic   = string
        payload = string
      })))
      events      = optional(list(object({
        name           = string
        event_notifier = string
        destinations   = list(object({
          target        = string
          configuration = map(string)
        }))
      })))
    }))
  }))
  default     = []
  description = "ONVIF camera devices and assets"
}
```

## Consequences

### Benefits

- **Vendor Independence**: Multi-vendor camera support with single connector
- **Standardized Discovery**: Automatic capability detection
- **PTZ Control**: Native pan, tilt, zoom operations
- **Event Monitoring**: Real-time motion and tampering alerts
- **Media Access**: Structured stream URI retrieval
- **Profile S/T Support**: H.264, JPEG, H.265 encoding
- **Industry Standard**: ONVIF certification ensures compatibility
- **Interoperability**: Works across manufacturers (Axis, Hikvision, Dahua, etc.)

### Trade-offs

- **SOAP/XML Overhead**: More verbose than REST/JSON
- **Pull-Based Events**: Polling vs push notifications (5-second interval)
- **ONVIF Requirement**: Cameras must be ONVIF-certified
- **Complexity**: ONVIF spec is comprehensive (implementation effort)
- **Network Traffic**: Persistent event polling creates baseline traffic

### Operational Impact

- **Monitoring**: Track discovery success, event throughput, PTZ command latency
- **Scaling**: Connection pooling for multiple cameras per edge location
- **Security**: Support for HTTP Digest Auth, TLS, client certificates
- **Testing**: Local simulator enables development without physical cameras

### Use Cases Enabled

- **Perimeter Security**: Motion detection for intrusion alerts
- **Industrial Monitoring**: Tampering detection for equipment protection
- **Video Analytics**: Stream URI access for AI/ML pipelines
- **Remote Operations**: PTZ control for operator-guided inspection
- **Multi-Vendor Deployments**: Unified interface across camera brands

### Migration Path

For existing camera integrations using vendor-specific APIs or RTSP:

1. Verify ONVIF certification of existing cameras
2. Test ONVIF compliance with ONVIF Device Test Tool
3. Extract camera credentials and network configuration
4. Configure `onvif-connector-assets.tfvars`
5. Test locally with Docker Compose simulator
6. Deploy via Terraform blueprint to staging
7. Validate discovery, events, and PTZ control
8. Migrate production cameras incrementally
9. Archive vendor-specific integration code

## Related Patterns

- **REST Connector**: Complementary for polling-based vendor APIs
- **SSE Connector**: Event streaming for non-ONVIF event sources
- **Media Connector**: RTSP streaming for pure video workloads
- **DataFlow Profiles**: MQTT message routing and transformation

## ONVIF Compliance and Standards

### Supported ONVIF Specifications

- **ONVIF Core Specification**: Version 21.06
- **Profile S**: IP video systems (video streaming, PTZ, audio, basic analytics)
- **Profile T**: Advanced video streaming (H.265, 4K, enhanced metadata)

### ONVIF Service Implementations

- **Device Service**: Mandatory (device info, capabilities, system date/time)
- **Media Service**: Mandatory (profiles, stream URIs, video configuration)
- **PTZ Service**: Optional (pan, tilt, zoom, presets)
- **Event Service**: Optional (pull messages, subscriptions)
- **Imaging Service**: Optional (brightness, contrast, focus)

### Known Limitations

- **WS-Discovery**: Not implemented (manual configuration required)
- **Event Push**: Uses pull messages pattern only (no push subscriptions)
- **Audio**: Not implemented in simulator
- **Recording**: Not supported (use separate VMS/NVR)
- **Analytics**: Basic motion detection only (vendor analytics vary)

## References

- [ONVIF Official Specifications](https://www.onvif.org/profiles/)
- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Akri Connector Framework](https://github.com/Azure/iot-operations-sdks)
- [ONVIF Connector Implementation](../../src/500-application/510-onvif-connector/README.md)
- [Blueprint Configuration Example](../../blueprints/full-single-node-cluster/terraform/onvif-connector-assets.tfvars.example)
- [ONVIF Device Test Tool](https://www.onvif.org/conformance/)

## Implementation Timeline

- **Phase 1**: Local development environment with Docker Compose ✅
- **Phase 2**: ONVIF camera simulator (Profile S/T, PTZ, events) ✅
- **Phase 3**: Connector client with discovery and MQTT integration ✅
- **Phase 4**: Terraform blueprint integration 📋
- **Phase 5**: Production deployment documentation 📋
- **Phase 6**: Enhanced authentication (HTTP Digest, x509 certs) 🔄
- **Phase 7**: WS-Discovery for automatic camera detection 📋
- **Phase 8**: Event push subscriptions (WS-BaseNotification) 📋

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*
