# Repository Analysis — Leak Detection Accelerator

## Executive Summary

The Edge AI repository is a modular, production-grade infrastructure-as-code and application platform for deploying Azure IoT Operations workloads at the edge. It provides a complete stack from cloud provisioning through edge cluster deployment to Rust microservices running on K3s with Azure Arc. The repository is directly applicable to the Leak Detection Accelerator for Oil & Gas with several components already containing leak-detection-specific artifacts.

**Critical finding:** The `509-sse-connector` already defines `ALERT_DLQC` (Detailed Leak Quality Control) event types with fields for `camera_id`, `leak_location` (longitude/latitude), `flow_rate`, and environmental data. This is a direct accelerator for the use case.

**Gap finding:** The `511-teams-notification` service exists as an empty scaffold — `services/teams-notification/src/` is empty. This must be implemented from scratch.

## Component Inventory

### Cloud Infrastructure (000-cloud/)

| Component | Purpose | Leak Detection Relevance |
|-----------|---------|--------------------------|
| `000-resource-group` | Resource group provisioning | Foundation — required |
| `010-security-identity` | Key Vault, managed identities, RBAC, Schema Registry | Secrets for edge-to-cloud auth, AIO identity |
| `020-observability` | Log Analytics, Azure Monitor, Managed Grafana | Alert dashboards, leak event monitoring |
| `030-data` | Storage Accounts, Data Lake Gen2, Schema Registry, ADR Namespace | Leak event archival, schema for telemetry payloads |
| `035-postgresql` | Flexible Server with TimescaleDB | Time-series leak event history, analytics |
| `040-messaging` | Event Grid Namespace (MQTT broker), Event Hubs, topics/subscriptions | Cloud-side event routing for leak alerts |
| `050-networking` | VNets, subnets, NSGs, Private DNS, NAT Gateway | Secure connectivity |
| `051-vm-host` | VM provisioning for edge cluster host | K3s host machine |
| `055-vpn-gateway` | Site-to-site and P2S VPN | Secure edge-to-cloud connectivity for remote sites |
| `060-acr` | Azure Container Registry | Container image hosting for Rust services |
| `070-kubernetes` | AKS cluster management | Optional cloud-side Kubernetes |
| `080-azureml` | Azure ML workspace | Model training for leak detection models |
| `085-ai-foundry` | Azure AI Foundry hub/projects | AI model management and RAI policies |

### Edge Infrastructure (100-edge/)

| Component | Purpose | Leak Detection Relevance |
|-----------|---------|--------------------------|
| `100-cncf-cluster` | K3s cluster with Azure Arc onboarding | Edge runtime for all services |
| `109-arc-extensions` | Arc Kubernetes extensions | Extension management |
| `110-iot-ops` | Azure IoT Operations — MQTT Broker, Dataflows, Akri, OPC UA | Core edge platform; Akri connectors for cameras/sensors |
| `111-assets` | Device Registry asset modeling (REST API 2025-10-01) | Asset definitions for leak detection sensors and cameras |
| `120-observability` | Arc extensions for Container Insights, Prometheus, Log Analytics | Edge monitoring and alerting |
| `130-messaging` | AIO Dataflows — EventHub, EventGrid, Fabric RTI modules | Edge-to-cloud data flow for leak events |
| `140-azureml` | Edge Azure ML deployment and inference | On-device model serving |

### Application Services (500-application/)

| Component | Purpose | Leak Detection Relevance | Status |
|-----------|---------|--------------------------|--------|
| `500-basic-inference` | Basic AI inference service | Reference pattern | Implemented |
| `501-rust-telemetry` | MQTT telemetry with OpenTelemetry tracing (AIO SDK) | Canonical AIO SDK pattern; sender/receiver reference | Implemented |
| `502-rust-http-connector` | HTTP sensor → MQTT broker | Sensor data ingestion pattern | Implemented |
| `503-media-capture-service` | RTSP ring buffer, event-driven video capture, ACSA cloud sync | Capture video evidence on leak detection | Implemented |
| `507-ai-inference` | Dual-backend AI inference (ONNX 220ms / Candle 155ms) | Edge inference for leak detection models | Implemented |
| `508-media-connector` | Multi-source media ingestion (IP cameras, RTSP, files) | Camera integration for visual leak detection | Implemented |
| `509-sse-connector` | SSE event streaming with AIO; **has ALERT_DLQC leak events** | Direct leak detection event source | Implemented |
| `510-onvif-connector` | ONVIF IP camera discovery, PTZ, event monitoring | Industrial camera integration | Implemented |
| `511-teams-notification` | Teams notification service | Leak alert notifications | **EMPTY SCAFFOLD** |

## Reusable Patterns and Code

### AIO SDK Rust Pattern (from 501-rust-telemetry receiver)

The canonical pattern for building AIO-connected Rust services:

```rust
// Connection setup
let connection_settings = MqttConnectionSettingsBuilder::from_environment().build();
let session = Session::new(connection_settings);
let application_context = ApplicationContextBuilder::default().build();
let mqtt_client = session.create_managed_client(application_context);

// Telemetry receiver
let receiver = telemetry::Receiver::<Payload, SessionManagedClient>::new(
    &mqtt_client, &topic_filter, None, telemetry::ReceiveOptions::default()
);

// Concurrent session + message processing via tokio::select!
tokio::select! {
    result = session.run() => { /* handle session */ },
    result = process_messages(&receiver) => { /* handle messages */ },
}
```

Key dependencies: `azure_iot_operations_mqtt` v0.9.0, `azure_iot_operations_protocol` v0.9.0, `azure_iot_operations_services` v0.8.0 (from `aio-sdks` registry).

### AI Inference Pattern (from 507-ai-inference)

Dual-backend inference with MQTT publishing:

* `InferenceEngine` — ONNX Runtime (220ms) or Candle (155ms) backends
* `MqttPublisher` — publishes inference results to AIO broker
* `TopicRouter` — routes results by topic: `edge-ai/{business_unit}/{facility}/{gateway_id}/{device_id}/ai/inference/vision`
* `HealthService` — HTTP health/readiness endpoints
* Graceful shutdown via `tokio::select!`

### Dataflow Pattern (from 130-messaging)

Three dataflow modules for edge-to-cloud data transport:

* **EventHub dataflow** — Source: AIO MQTT default endpoint → Destination: Event Hub (Kafka protocol, UAMI auth)
* **EventGrid dataflow** — Source: AIO MQTT → Destination: Event Grid MQTT broker
* **Fabric RTI dataflow** — Source: AIO MQTT → Destination: Fabric Real-Time Intelligence

Each uses `azapi_resource` with `Microsoft.IoTOperations/instances/dataflowEndpoints` and `dataflowProfiles/dataflows` resource types. PassThrough transformation by default.

### Event-Driven Video Capture (from 503-media-capture-service)

* In-memory ring buffer for continuous RTSP stream capture
* MQTT-triggered capture (alert events or manual commands)
* Azure Connected Storage Account (ACSA) for cloud sync to Blob Storage
* Directly applicable: trigger video capture when `ALERT_DLQC` event fires

## Architecture Blueprint Composition

The `full-single-node-cluster` blueprint demonstrates end-to-end composition with 16 module invocations:

1. `cloud_resource_group` → foundation
2. `cloud_networking` → VNet, subnets, NSG, optional NAT/Private Resolver
3. `cloud_security_identity` → Key Vault, managed identities, RBAC
4. `cloud_vpn_gateway` → optional VPN
5. `cloud_observability` → Log Analytics, Monitor, Grafana
6. `cloud_data` → Storage, Schema Registry, ADR Namespace
7. `cloud_postgresql` → optional PostgreSQL
8. `cloud_managed_redis` → optional Redis
9. `cloud_messaging` → Event Grid, Event Hubs
10. `cloud_vm_host` → VM for K3s
11. `cloud_acr` → Container Registry
12. `cloud_kubernetes` → optional AKS
13. `cloud_azureml` → optional Azure ML
14. `cloud_ai_foundry` → optional AI Foundry
15. `edge_cncf_cluster` → K3s + Arc onboarding
16. `edge_arc_extensions` → Arc Kubernetes extensions
17. `edge_iot_ops` → AIO with Akri connectors (REST, Media, ONVIF, SSE all configurable via feature flags)
18. `edge_assets` → Device Registry assets
19. `edge_observability` → Container Insights, Prometheus, Log Analytics
20. `edge_messaging` → Dataflows to EventHub/EventGrid/Fabric RTI
21. `edge_azureml` → optional edge ML

Module outputs chain as inputs to dependent modules (e.g., `cloud_security_identity.aio_identity` → `edge_iot_ops`, `cloud_data.adr_namespace` → `edge_messaging`).

## Leak Detection Data Flow Architecture

Based on existing components, the leak detection data flow follows this path:

```text
Camera/Sensor → SSE Connector (509) → AIO MQTT Broker → AI Inference (507)
                                                            ↓
                                              Leak Detected (ALERT_DLQC)
                                                            ↓
                                            ┌───────────────┼───────────────┐
                                            ↓               ↓               ↓
                                     Media Capture    Edge Messaging    Teams Notify
                                        (503)           (130)            (511)
                                            ↓               ↓
                                      Cloud Storage    Event Hub/Grid
                                                            ↓
                                                    Cloud Processing
                                                    Dashboards (020)
```

## Gap Analysis for Leak Detection

### Ready to Use

* **509-sse-connector**: Already has `ALERT_DLQC` event type with leak-specific fields
* **507-ai-inference**: Production-ready dual-backend inference engine
* **503-media-capture-service**: Event-driven video capture with cloud sync
* **130-messaging**: Dataflow modules for edge-to-cloud transport
* **110-iot-ops**: Full AIO deployment with Akri connector support
* **501-rust-telemetry**: Reference AIO SDK patterns for new services

### Must Build

* **511-teams-notification**: Empty scaffold — needs full Rust implementation
  * Should follow 501 AIO SDK patterns
  * Subscribe to leak alert MQTT topic
  * Call Microsoft Teams webhook API
  * Include severity-based routing and rate limiting

### Should Customize

* **111-assets**: Define leak detection sensor assets (pressure, flow, acoustic sensors)
* **130-messaging**: Add leak-detection-specific dataflow endpoints
* **Blueprint**: Consider a `leak-detection-single-node` blueprint composing relevant components
* **507-ai-inference**: Train and deploy leak detection model (visual or sensor-fusion)

## Technology Stack Summary

| Layer | Technology | Version/Detail |
|-------|-----------|----------------|
| Language | Rust | Independent Cargo.lock per service (workspace disabled) |
| Edge Runtime | K3s + Azure Arc | CNCF-compliant, Arc-enabled |
| Edge Platform | Azure IoT Operations | MQTT Broker, Dataflows, Akri, Device Registry |
| Edge SDK | AIO Rust SDK | mqtt v0.9.0, protocol v0.9.0, services v0.8.0 |
| IaC | Terraform + Bicep | Modular components, azapi provider for AIO resources |
| Cloud Messaging | Event Grid + Event Hubs | Namespace-based MQTT + Kafka protocol |
| Observability | OpenTelemetry + Azure Monitor + Grafana | Distributed tracing, dashboards |
| AI/ML | ONNX Runtime + Candle | Dual-backend inference |
| Container Registry | Azure Container Registry | Private registry with ACR pull for AIO |
| Local Dev | Docker Compose | Per-service compose files |

## Key Files Reference

| File | Significance |
|------|-------------|
| `src/500-application/509-sse-connector/` | Leak detection events (ALERT_DLQC) already defined |
| `src/500-application/507-ai-inference/services/ai-edge-inference/src/main.rs` | Inference engine pattern |
| `src/500-application/501-rust-telemetry/services/receiver/src/main.rs` | Canonical AIO SDK receiver pattern |
| `src/100-edge/130-messaging/terraform/main.tf` | Dataflow module composition |
| `src/100-edge/130-messaging/terraform/modules/eventhub/main.tf` | Dataflow endpoint + flow resource pattern |
| `src/100-edge/110-iot-ops/` | AIO deployment with Akri connectors |
| `src/100-edge/111-assets/` | Device Registry asset modeling |
| `blueprints/full-single-node-cluster/terraform/main.tf` | Blueprint composition reference |
| `src/500-application/511-teams-notification/` | Empty scaffold — must implement |
