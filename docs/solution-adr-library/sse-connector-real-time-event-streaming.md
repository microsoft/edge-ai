---
title: SSE Connector for Real-Time Event Streaming
description: Architecture Decision Record for implementing Server-Sent Events (SSE) connector in Azure IoT Operations to enable real-time event streaming from edge devices. Addresses event-driven architectures, low-latency monitoring, and persistent connection management for continuous data streams from industrial IoT devices like analytics cameras and monitoring systems.
author: Edge AI Team
ms.date: 2025-11-18
ms.topic: architecture-decision-record
estimated_reading_time: 8
keywords:
  - sse-connector
  - server-sent-events
  - akri-connector
  - real-time-streaming
  - azure-iot-operations
  - event-driven
  - persistent-connections
  - analytics-camera
  - leak-detection
  - edge-computing
  - mqtt-broker
  - event-streaming
  - adr
---

## Status

- [ ] Draft
- [X] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

Industrial IoT environments require real-time event streaming capabilities for monitoring systems,
alert notifications, and continuous data streams. Traditional polling-based REST connectors
introduce latency and increased network overhead due to frequent request-response cycles.

Server-Sent Events (SSE) provide a standard HTTP-based protocol for servers to push real-time
updates to clients over persistent connections, making it ideal for event-driven IoT architectures
where immediate notification of state changes, alerts, or analytics results is critical.

Use cases include:

- Real-time leak detection from analytics cameras
- Continuous health monitoring and heartbeat events
- Alert and alarm notifications
- Analytics state changes (enabled/disabled)
- Live sensor readings requiring low-latency delivery

## Decision

Implement an Akri SSE HTTP Connector for Azure IoT Operations that:

1. Maintains persistent HTTP connections to SSE endpoints
2. Receives and processes Server-Sent Events in real-time
3. Maps event types to MQTT topics for downstream processing
4. Provides local development environment with Docker Compose
5. Integrates with Terraform-based blueprint deployments
6. Supports event schema inference and validation

## Decision Drivers

- **Low Latency**: Near real-time event delivery vs polling delays
- **Efficiency**: Single persistent connection vs multiple polling requests
- **Event-Driven**: Server-initiated updates match IoT event patterns
- **Standardization**: SSE is a W3C standard with broad client support
- **Simplicity**: Text-based protocol over HTTP/HTTPS
- **Compatibility**: Works with existing MQTT infrastructure

## Considered Options

### Option A: REST Polling Connector (Current Solution)

**Pros:**

- Already implemented and proven
- Simple request-response pattern
- Works for periodic data collection
- Good for stateless operations

**Cons:**

- Polling introduces latency (depends on interval)
- Increased network traffic and overhead
- Server resources wasted on frequent polling
- Not suitable for immediate event notification

### Option B: WebSocket Connector

**Pros:**

- Full-duplex bidirectional communication
- Real-time, low-latency
- Binary protocol support

**Cons:**

- More complex implementation
- Overkill for server-to-client streaming
- Requires WebSocket library/framework
- Additional protocol overhead

### Option C: SSE Connector (Selected)

**Pros:**

- Simple, text-based protocol over HTTP
- Standard browser API and widespread support
- Automatic reconnection with built-in retry
- Works through firewalls and proxies
- Lower complexity than WebSockets
- Perfect fit for server-to-client streaming

**Cons:**

- Unidirectional (server to client only)
- Limited to UTF-8 text encoding
- Requires HTTP/1.1 or higher

### Option D: gRPC Streaming

**Pros:**

- High performance binary protocol
- Bidirectional streaming
- Strong typing with Protocol Buffers

**Cons:**

- Complex implementation
- Requires gRPC infrastructure
- Not HTTP/1.1 compatible
- Overkill for simple event streaming

## Decision Conclusion

The SSE Connector was selected as the optimal solution for real-time event streaming requirements
in Azure IoT Operations edge environments.

### Architecture

The SSE Connector architecture consists of:

```plaintext
┌─────────────────────┐
│  Analytics Camera   │
│  SSE Endpoint       │
│  /camera-events     │
└──────────┬──────────┘
           │ HTTP/1.1 SSE
           │ Persistent Connection
           ▼
┌─────────────────────┐
│  Akri SSE Connector │
│  - Event Parser     │
│  - Type Mapper      │
│  - Retry Logic      │
└──────────┬──────────┘
           │ MQTT Publish
           ▼
┌─────────────────────┐
│  MQTT Broker        │
│  Topic Routes:      │
│  - heartbeat        │
│  - alert            │
│  - alert-dlqc       │
│  - analytics-*      │
└─────────────────────┘
```

### Component Structure

```plaintext
src/500-application/509-sse-connector/
├── services/
│   ├── sse-server/              # Analytics camera simulator
│   │   ├── sse_server.py        # Event generation
│   │   └── Dockerfile
│   └── connector-test-client/   # Connector simulation
│       ├── connector_client.py  # SSE client + MQTT publisher
│       └── Dockerfile
├── docker-compose.yml           # Local dev environment
├── charts/                      # Kubernetes Helm charts
└── README.md                    # Complete documentation
```

### Event Types and Schema

The SSE Connector handles these event types for analytics camera use case:

**HEARTBEAT** - Device health status:

```json
{
  "type": "HEARTBEAT",
  "timestamp": 1705339200000
}
```

**ALERT** - Basic anomaly detection:

```json
{
  "type": "ALERT",
  "timestamp": 1705339205000,
  "message": "leak",
  "event_id": 1001
}
```

**ALERT_DLQC** - Detailed leak detection with location and environmental data:

```json
{
  "type": "ALERT_DLQC",
  "timestamp": 1705339210000,
  "message": "leak",
  "event_id": 1002,
  "camera_id": 3,
  "leak_location": {"latitude": 64.55, "longitude": 35.78},
  "flow_rate": 0.71,
  "confidence_level": 85,
  "temperature": 38.2
}
```

**ANALYTICS_ENABLED/DISABLED** - Analytics state changes:

```json
{
  "type": "ANALYTICS_ENABLED",
  "timestamp": 1705339215000,
  "analytics_type": "leak detection"
}
```

### Deployment Options

#### 1. Local Development (Docker Compose)

Quick start for testing and development:

```bash
cd src/500-application/509-sse-connector
docker compose up -d
```

Provides:

- SSE server generating sample events
- Connector test client
- Local MQTT broker
- MQTT monitor

#### 2. Production Deployment (Terraform)

Blueprint-based deployment:

```bash
cd blueprints/full-single-node-cluster/terraform
terraform apply -var-file="sse-connector-assets.tfvars"
```

Configuration example in `sse-connector-assets.tfvars.example` demonstrates:

- Device endpoint definitions
- Asset configurations with event types
- MQTT topic mappings
- Multiple camera support

### Event to MQTT Topic Mapping

Events are routed based on `event_notifier` field:

```terraform
events = [
  {
    name           = "HEARTBEAT"
    event_notifier = "HEARTBEAT"
    destinations = [
      {
        target = "Mqtt"
        configuration = {
          topic = "events/.../analytics-camera-01/heartbeat"
          qos   = "Qos1"
        }
      }
    ]
  }
]
```

### Connector Features

- **Automatic Reconnection**: Exponential backoff (1s → 60s max delay)
- **Event Schema Inference**: JSON payload parsing and validation
- **Error Handling**: Retry logic for MQTT publish failures
- **Observability**: Connection state, event statistics, error counts
- **Security**: Supports Anonymous, Username/Password, x509 (planned)

### Integration with Akri Framework

The SSE Connector leverages the Akri connector module:

- **ConnectorTemplate**: Defines SSE endpoint type (`Microsoft.SSEHttp`)
- **Device Registry**: Namespaced devices with SSE endpoint configurations
- **Asset Definitions**: Event-based asset model (vs datasets for REST)
- **MQTT Configuration**: Shared broker settings across connectors

### Configuration Variables

Terraform variables in `src/100-edge/110-iot-ops/terraform/variables.akri.tf`:

```terraform
variable "should_enable_akri_sse_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri SSE Connector template"
}
```

Custom connector support:

```terraform
custom_akri_connectors = [{
  name     = "analytics-camera-sse"
  type     = "sse"
  replicas = 1
  log_level = "info"
}]
```

## Consequences

### Benefits

- **Real-Time Events**: Immediate notification vs polling delays
- **Resource Efficiency**: Single connection vs continuous polling
- **Lower Latency**: Event delivery in milliseconds
- **Standard Protocol**: HTTP/1.1 SSE is widely supported
- **Simple Implementation**: Text-based protocol, easier than WebSockets
- **Automatic Recovery**: Built-in reconnection handling
- **Firewall Friendly**: Works over standard HTTP/HTTPS ports

### Trade-offs

- **Unidirectional**: Server to client only (sufficient for monitoring)
- **Text Only**: UTF-8 encoding (acceptable for JSON events)
- **Connection Management**: Persistent connections require proper handling
- **Browser Limit**: ~6 concurrent SSE connections per domain (not relevant for IoT)

### Operational Impact

- **Monitoring**: Track SSE connection state and event throughput
- **Scaling**: Connection pooling for multiple cameras/endpoints
- **Network**: Persistent connections through corporate firewalls
- **Testing**: Local Docker Compose environment simplifies development

### Migration Path

For existing systems using legacy deployment scripts:

1. Extract event types and MQTT topic mappings
2. Configure `sse-connector-assets.tfvars`
3. Test locally with docker compose
4. Deploy via Terraform blueprint
5. Verify event flow
6. Archive legacy scripts

## Related Patterns

- **REST Connector**: Complementary for polling-based data collection
- **Media Connector**: Similar event-driven pattern for video streams
- **ONVIF Connector**: Camera-specific protocol (different from SSE)
- **DataFlow Profiles**: MQTT message routing and transformation

## References

- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [Azure IoT Operations Documentation](https://learn.microsoft.com/en-us/azure/iot-operations/)
- [Akri Connector Framework](https://github.com/Azure/iot-operations-sdks)
- [SSE Connector Implementation](../../src/500-application/509-sse-connector/README.md)
- [Blueprint Configuration Example](../../blueprints/full-single-node-cluster/terraform/sse-connector-assets.tfvars.example)

## Implementation Timeline

- **Phase 1**: Local development environment with Docker Compose ✅
- **Phase 2**: SSE server simulator with analytics camera events ✅
- **Phase 3**: Connector test client with MQTT integration ✅
- **Phase 4**: Terraform blueprint integration ✅
- **Phase 5**: Production deployment documentation ✅
- **Phase 6**: Enhanced authentication (Username/Password, x509) 🔄
- **Phase 7**: Helm charts for Kubernetes deployment 📋

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*
