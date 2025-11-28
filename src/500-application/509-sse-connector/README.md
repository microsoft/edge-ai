---
title: Akri SSE HTTP Connector
description: Complete standalone development and demo environment for integrating Server-Sent Events (SSE) endpoints with Azure IoT Operations using the Akri connector framework
author: Edge AI Team
ms.date: 2025-11-18
ms.topic: reference
estimated_reading_time: 8
keywords:
  - azure iot operations
  - akri connector
  - sse connector
  - server-sent events
  - event streaming
  - real-time events
  - edge computing
  - docker compose
  - terraform
---

## Akri SSE HTTP Connector

The Akri SSE HTTP Connector provides a complete, standalone development and testing environment
for integrating Server-Sent Events (SSE) endpoints with Azure IoT Operations. This component
demonstrates how to use the Akri connector framework to discover, connect to, and manage SSE
event streams as assets in the Azure IoT Operations ecosystem.

This application component provides two deployment modes:

1. **Local Development Environment**: Docker Compose setup for development, testing, and demonstration
2. **Production Deployment (Terraform)**: ⚠️ **RECOMMENDED** - Use Terraform-based deployment via blueprints

The connector enables Azure IoT Operations to maintain persistent connections to SSE endpoints
and forward real-time events to destinations such as MQTT brokers or state stores as they occur.

> **💡 RECOMMENDED APPROACH**: For production deployments, use the Terraform-based configuration in
> the `full-single-node-cluster` blueprint with the `sse-connector-assets.tfvars.example` file as a
> reference for configuring your SSE connector assets.

## What is Server-Sent Events (SSE)?

Server-Sent Events (SSE) is a standard for servers to push real-time updates to clients over HTTP.
Unlike REST endpoints that require polling, SSE maintains a persistent connection and streams events
as they occur, making it ideal for:

- Real-time monitoring systems
- Continuous data streams
- Event-driven applications
- Alert and notification systems
- Live analytics dashboards

SSE events are text-based, UTF-8 encoded, and follow a simple format with event types and data payloads.

## Use Case: Analytics Camera SSE Connector

This implementation includes an Analytics Camera SSE server simulator that
generates real-time leak detection events, demonstrating a practical industrial IoT use case.

### Analytics Camera Event Types

The Analytics Camera SSE server generates the following event types:

- **HEARTBEAT**: Device health status (every 5 seconds)
- **ALERT**: Basic anomaly detection events
- **ALERT_DLQC**: Detailed leak detection with location, flow rate, environmental data
- **ANALYTICS_ENABLED**: Analytics activation notifications
- **ANALYTICS_DISABLED**: Analytics deactivation notifications

## Local Development Architecture

The Docker Compose environment simulates a complete Azure IoT Operations ecosystem:

- **MQTT Broker**: Local Mosquitto broker for message routing
- **SSE Server**: Simulated analytics camera generating real-time events
- **Connector Test Client**: Simulates the Akri SSE connector behavior
- **MQTT Monitor**: Real-time message monitoring for debugging

## Azure IoT Operations Integration

For Azure IoT Operations deployments, the component uses:

- **Connector Templates**: Deployed via the `110-iot-ops` component's `akri-connectors` module
- **Device Endpoints**: Kubernetes resources defining SSE endpoint configurations
- **Asset Definitions**: Resources configuring event types and MQTT destinations
- **Event Streaming**: Real-time event forwarding to MQTT topics

## Deployment Prerequisites

### Local Development

- **Docker**: Version 20.10+ with Docker Compose support
- **curl**: For testing SSE endpoints
- **mosquitto-clients** (optional): For MQTT testing with `mosquitto_sub`

### Azure IoT Operations Integration (Terraform - Recommended)

- **Blueprint Deployment**: Use `full-single-node-cluster` blueprint with SSE connector variables
- **Terraform**: Version 1.9.8 or later
- **Azure Subscription**: Active subscription with appropriate permissions
- **Example Configuration**: Reference `blueprints/full-single-node-cluster/terraform/sse-connector-assets.tfvars.example`

## Quick Start

### 1. Local Development Environment Setup

Start the complete local development environment:

```bash
# Navigate to the component directory
cd src/500-application/509-sse-connector

# Start all services
docker compose up -d

# View service status
docker compose ps

# View logs
docker compose logs -f

# Stop the environment
docker compose down
```

### 2. Verify SSE Server

Test the SSE endpoint directly:

```bash
# Connect to SSE stream (shows live events)
curl -N -H "Accept: text/event-stream" http://localhost:8080/camera-events

# Check server health
curl http://localhost:8080/health

# Get server information
curl http://localhost:8080/
```

Expected SSE output:

```text
event: HEARTBEAT
data: {"type":"HEARTBEAT","timestamp":1705339200000}

event: ALERT
data: {"type":"ALERT","timestamp":1705339205000,"message":"leak","event_id":1001}

event: ALERT_DLQC
data: {"type":"ALERT_DLQC","timestamp":1705339210000,"message":"leak","event_id":1002,"camera_id":3,"leak_location":{"longitude":35.78,"latitude":64.55},...}
```

### 3. Monitor MQTT Messages

Watch events being forwarded to MQTT:

```bash
# Subscribe to all camera events
docker exec -it sse-mqtt-monitor mosquitto_sub -h mosquitto-broker -t 'camera-events/#' -v

# Subscribe to specific event types
docker exec -it sse-mqtt-monitor mosquitto_sub -h mosquitto-broker -t 'camera-events/alert' -v
docker exec -it sse-mqtt-monitor mosquitto_sub -h mosquitto-broker -t 'camera-events/alert-dlqc' -v
```

### 4. View Connector Statistics

```bash
# Check connector test client logs
docker logs -f sse-connector-test-client
```

Expected output:

```text
INFO - Connected to SSE endpoint successfully
INFO - Received HEARTBEAT event
INFO - Received ALERT event
INFO - === SSE Connector Statistics ===
INFO - Events Received: 45
INFO - Events Published: 45
INFO - Events by Type:
INFO -   HEARTBEAT: 20
INFO -   ALERT: 15
INFO -   ALERT_DLQC: 10
```

## Production Deployment Using Terraform

**RECOMMENDED** - Deploy SSE connector assets using Infrastructure as Code:

### Setup Prerequisites

1. Deploy the `full-single-node-cluster` blueprint (or another blueprint with IoT Operations)
2. Ensure SSE endpoints are accessible from the cluster

### Terraform Configuration

Create or modify `sse-connector-assets.tfvars` in the blueprint:

```bash
cd blueprints/full-single-node-cluster/terraform

# Copy example configuration
cp sse-connector-assets.tfvars.example sse-connector-assets.tfvars

# Edit configuration to match your SSE endpoints
```

### Deploy

```bash
# Preview changes
terraform plan -var-file="sse-connector-assets.tfvars"

# Apply configuration
terraform apply -var-file="sse-connector-assets.tfvars"
```

### Verify

```bash
# Check deployed devices and assets
kubectl get devices,assets -n azure-iot-operations

# Check connector instances
kubectl get connectorinstance,connectortemplate -n azure-iot-operations

# View connector logs
kubectl logs -l app.kubernetes.io/name=sse-connector -n azure-iot-operations --tail=100 -f

# Monitor MQTT messages
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  sh -c "mosquitto_sub --host aio-broker.azure-iot-operations --port 18883 \
         --username 'K8S-SAT' --pw \$(cat /var/run/secrets/tokens/broker-sat) \
         --cafile /var/run/certs/ca.crt --topic 'events/#' -v"
```

**Configuration Reference**: See `blueprints/full-single-node-cluster/terraform/sse-connector-assets.tfvars.example`
for a complete example of all available configuration options.

## SSE vs REST Connectors

Understanding when to use SSE vs REST connectors:

| Feature             | SSE Connector                | REST Connector                        |
|---------------------|------------------------------|---------------------------------------|
| **Connection Type** | Persistent, long-lived       | Request-response, short-lived         |
| **Data Flow**       | Server pushes to client      | Client polls server                   |
| **Latency**         | Near real-time               | Depends on polling interval           |
| **Resource Usage**  | 1 connection, lower overhead | Multiple connections, higher overhead |
| **Use Case**        | Event streams, notifications | Periodic data collection              |
| **Asset Type**      | Events                       | Datasets                              |
| **Best For**        | Real-time monitoring, alerts | Sensor readings, status checks        |

### When to Use SSE Connector

- Real-time event notifications (alerts, alarms)
- Continuous monitoring systems
- Low-latency requirements
- Server-initiated updates
- Event-driven architectures

### When to Use REST Connector

- Periodic sensor readings
- On-demand data retrieval
- Stateless operations
- Polling-based data collection

## Architecture Details

### SSE Server Simulator (`services/sse-server/`)

Python-based SSE server that generates analytics camera events:

```python
# Generates events with realistic intervals
- HEARTBEAT: Every 5 seconds
- ANALYTICS_ENABLED/DISABLED: Randomly toggled
- ALERT: 10% probability per check
- ALERT_DLQC: 70% of alerts include detailed data
```

**Environment Variables**:

- `PORT`: HTTP server port (default: 8080)
- `DEVICE_ID`: Device identifier (default: analytics-camera-001)
- `HEARTBEAT_INTERVAL`: Seconds between heartbeats (default: 5)
- `ALERT_PROBABILITY`: Chance of alert per check (default: 0.1)

### Connector Test Client (`services/connector-test-client/`)

Python client that simulates Akri SSE connector behavior:

```python
# Connects to SSE endpoint
# Parses events by type
# Publishes to MQTT topics based on event_notifier
# Handles reconnection with exponential backoff
```

**Environment Variables**:

- `SSE_ENDPOINT`: SSE server URL
- `AIO_BROKER_HOSTNAME`: MQTT broker hostname
- `AIO_BROKER_TCP_PORT`: MQTT broker port
- `TOPIC_HEARTBEAT`: Topic for heartbeat events
- `TOPIC_ALERT`: Topic for alert events
- `TOPIC_ALERT_DLQC`: Topic for detailed alert events
- `TOPIC_ANALYTICS_ENABLED`: Topic for analytics enabled events
- `TOPIC_ANALYTICS_DISABLED`: Topic for analytics disabled events

### Event to Topic Mapping

The connector routes events based on the `event_notifier` field in the asset definition:

```terraform
events = [
  {
    name           = "HEARTBEAT"
    event_notifier = "HEARTBEAT"  # Matches SSE event type
    destinations = [
      {
        target = "Mqtt"
        configuration = {
          topic = "events/.../heartbeat"
        }
      }
    ]
  }
]
```

## Troubleshooting

### SSE Server Not Starting

```bash
# Check container status
docker ps -a | grep sse-server

# View logs
docker logs sse-server

# Verify port availability
lsof -i :8080  # Should be free or used by sse-server
```

### No Events Received

```bash
# Test SSE endpoint directly
curl -N -H "Accept: text/event-stream" http://localhost:8080/camera-events

# Should see live events streaming
# Press Ctrl+C to stop

# Check connector client logs
docker logs sse-connector-test-client

# Verify MQTT broker connectivity
docker logs mosquitto-broker
```

### Events Not Appearing in MQTT

```bash
# Check MQTT monitor
docker logs sse-mqtt-monitor

# Subscribe to all topics
docker exec -it sse-mqtt-monitor mosquitto_sub -h mosquitto-broker -t '#' -v

# Check connector client connection
docker logs sse-connector-test-client | grep "Connected to MQTT"
```

### Production Deployment Issues

```bash
# Check connector pod status
kubectl get pods -n azure-iot-operations | grep sse-connector

# View connector logs
kubectl logs -l app.kubernetes.io/name=sse-connector -n azure-iot-operations

# Check device and asset status
kubectl describe device analytics-camera -n azure-iot-operations
kubectl describe asset analytics-camera-asset -n azure-iot-operations

# Verify SSE endpoint accessibility from cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -N -H "Accept: text/event-stream" http://your-sse-endpoint/events
```

## Development and Customization

### Adding New Event Types

1. Update SSE server to generate new events:

```python
# In services/sse-server/sse_server.py
yield {
    'type': 'MY_NEW_EVENT',
    'timestamp': timestamp,
    'custom_field': 'value'
}
```

1. Add event to asset configuration:

```terraform
events = [
  {
    name           = "MY_NEW_EVENT"
    event_notifier = "MY_NEW_EVENT"
    destinations = [...]
  }
]
```

1. Update connector client topic mapping:

```python
# In services/connector-test-client/connector_client.py
topic_map = {
    'MY_NEW_EVENT': os.getenv('TOPIC_MY_NEW_EVENT', 'events/my-new-event')
}
```

### Custom SSE Endpoints

To integrate with your own SSE endpoints:

1. Update `SSE_ENDPOINT` environment variable
2. Configure event_notifier to match your event types
3. Adjust MQTT topic structure as needed

### Performance Tuning

**SSE Server**:

- `HEARTBEAT_INTERVAL`: Reduce for more frequent health checks
- `ALERT_PROBABILITY`: Adjust event frequency

**Connector Client**:

- Add connection pooling for multiple endpoints
- Implement batching for high-volume events
- Configure QoS levels for MQTT delivery guarantees

## Security Considerations

### Authentication

The SSE connector supports:

- **Anonymous** (current implementation, for development)
- **Username/Password** (basic auth, coming soon)
- **x509 Certificates** (client certs, coming soon)

### TLS/SSL

For production deployments:

1. Use HTTPS endpoints for SSE connections
2. Configure trust settings in connector template
3. Use TLS for MQTT connections

### Network Security

- Deploy SSE servers within secure networks
- Use Kubernetes network policies to restrict access
- Implement firewall rules for endpoint access

## Migration from Legacy Deployment Scripts

If migrating from legacy SSE connector deployment scripts:

### Key Differences

| Legacy               | New Structure              |
|----------------------|----------------------------|
| Shell scripts        | Docker Compose + Terraform |
| Manual kubectl apply | Infrastructure as Code     |
| Inline YAML          | Modular services           |
| No local testing     | Complete local environment |

### Migration Steps

1. **Review** existing connector configuration from legacy scripts
2. **Extract** event types and MQTT topic mappings
3. **Configure** `sse-connector-assets.tfvars` with your settings
4. **Test** locally with docker compose
5. **Deploy** via Terraform blueprint
6. **Verify** events are flowing correctly
7. **Archive** legacy deployment scripts

## Related Documentation

- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Akri Connector Framework](https://github.com/Azure/iot-operations-sdks)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [REST HTTP Connector](../505-akri-rest-http-connector/README.md) - Similar connector for polling endpoints
- [Blueprint Documentation](../../../blueprints/full-single-node-cluster/README.md)

## Contributing

When contributing to this component:

1. Follow the established Terraform module structure
2. Update documentation for any configuration changes
3. Test locally with Docker Compose before deployment
4. Validate against Azure IoT Operations compatibility
5. Include example configurations for new features

## Support

For issues and questions:

- Check the troubleshooting section above
- Review `blueprints/full-single-node-cluster/terraform/sse-connector-assets.tfvars.example`
  for configuration reference
- Review Azure IoT Operations documentation
- File issues in the project repository
- Contact the Edge AI team for component-specific questions

## Appendix: Event Schema Examples

### HEARTBEAT Event

```json
{
  "type": "HEARTBEAT",
  "timestamp": 1705339200000
}
```

### ALERT Event

```json
{
  "type": "ALERT",
  "timestamp": 1705339205000,
  "message": "leak",
  "event_id": 1001
}
```

### ALERT_DLQC Event (Detailed)

```json
{
  "type": "ALERT_DLQC",
  "timestamp": 1705339210000,
  "message": "leak",
  "event_id": 1002,
  "camera_id": 3,
  "leak_location": {
    "longitude": 35.78269848040571,
    "latitude": 64.55565678374194
  },
  "camera_location": {
    "longitude": -171.2156123298313,
    "latitude": 64.08392306220344
  },
  "flow_rate": 0.714703905661418,
  "unit": "g/s",
  "mass": 3.207630462504989,
  "mass_unit": "kg",
  "confidence_level": 28,
  "camera_orientation": 92,
  "depression_angle": 52,
  "wind_speed": 34.19892851403805,
  "wind_speed_unit": "m/h",
  "wind_direction": 149,
  "temperature": 38.19919186189587,
  "temperature_unit": "F",
  "humidity": 99
}
```

### ANALYTICS_ENABLED Event

```json
{
  "type": "ANALYTICS_ENABLED",
  "timestamp": 1705339215000,
  "analytics_type": "leak detection"
}
```

### ANALYTICS_DISABLED Event

```json
{
  "type": "ANALYTICS_DISABLED",
  "timestamp": 1705339220000,
  "analytics_type": "leak detection"
}
```

---

*AI and automation capabilities described in this component should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
