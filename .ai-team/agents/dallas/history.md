# History — Dallas

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)
- **Stack:** Terraform, Bicep, Rust, Azure IoT Operations, Azure Arc, K3s
- **Goal:** Analyze the existing Edge AI repo and design+implement a Leak Detection use case. Edge inference → event propagation → Teams notification.
- **Repo structure:** Cloud infra (000-cloud/), Edge infra (100-edge/), Applications (500-application/), Utilities (900-tools-utilities/), Blueprints (blueprints/)
- **Key components:** Resource groups, security/identity, observability, data/storage, messaging (Event Grid/Hubs/Service Bus), networking, ACR, Kubernetes, IoT Ops, CNCF cluster, assets, edge messaging

## Learnings

### 2025-07-16: Repository Analysis Complete

* **509-sse-connector has ALERT_DLQC events built in.** The SSE connector already defines leak detection event types with camera_id, leak_location (longitude/latitude), flow_rate, and environmental data. This was the single most important discovery — the use case was anticipated in the original design.
* **511-teams-notification is an empty scaffold.** The directory structure exists (`services/teams-notification/src/`) but contains no source code, no Cargo.toml, nothing. This is the primary implementation gap for Parker.
* **AIO SDK Rust pattern is well-established.** The 501-rust-telemetry receiver demonstrates the canonical pattern: `MqttConnectionSettingsBuilder::from_environment()` → `Session` → `ApplicationContextBuilder` → `telemetry::Receiver<Payload, SessionManagedClient>` → `tokio::select!` for concurrent session and message processing. SDK versions: mqtt v0.9.0, protocol v0.9.0, services v0.8.0 from `aio-sdks` registry.
* **507-ai-inference provides dual-backend inference.** ONNX Runtime (220ms) and Candle (155ms) backends with MQTT publisher and topic routing. Production-ready for deploying leak detection models.
* **503-media-capture-service enables evidence capture.** MQTT-triggered video capture from RTSP streams with cloud sync via ACSA. Can be wired to capture video evidence when ALERT_DLQC fires.
* **130-messaging has three dataflow modules.** EventHub (Kafka protocol), EventGrid (MQTT), and Fabric RTI. Each is conditional on feature flags. Uses `azapi_resource` with `Microsoft.IoTOperations` resource types at API version 2025-10-01.
* **Blueprint composition uses module output chaining.** The full-single-node-cluster blueprint has 21 module invocations with explicit dependency ordering. Key output chains: `cloud_security_identity.aio_identity` → multiple edge modules, `cloud_data.adr_namespace` → edge_messaging, `cloud_data.schema_registry` → edge_iot_ops.
* **Root Cargo.toml has workspace disabled.** Each Rust service has independent Cargo.lock for microservices architecture — independent deployment lifecycles and per-service SBOMs. No shared workspace dependencies.
* **111-assets uses Device Registry REST API 2025-10-01 (stable) and 2025-11-01-preview.** Asset endpoint profiles + asset instances with datasets and datapoints. This is where leak detection sensor assets would be defined.
* **Akri connectors are feature-flagged in 110-iot-ops.** REST HTTP, Media, ONVIF, and SSE connectors can each be independently enabled via `should_enable_akri_*` variables. Custom connectors also supported via `custom_akri_connectors`.

### 2025-07-16: Design Proposal Complete

* **ALERT_DLQC canonical schema has 18 fields.** Pinned from `events_simulator.py` (line 125): type, timestamp, message, event_id, camera_id, leak_location{lon,lat}, camera_location{lon,lat}, flow_rate, unit, mass, mass_unit, confidence_level, camera_orientation, depression_angle, wind_speed, wind_speed_unit, wind_direction, temperature, temperature_unit, humidity. All downstream agents must use this exact schema.
* **Severity derivation from confidence_level.** Critical (80–100), High (60–79), Medium (40–59), Low (0–39). Maps to Teams Adaptive Card container styles: Attention, Warning, Accent, Good.
* **MQTT topic hierarchy established.** `events/{facility}/{device_id}/camera/*` for operational, `alerts/{facility}/{device_id}/leak/dlqc` for leak alerts (QoS 1), `notifications/{facility}/{device_id}/teams/*` for notification status, `media/{facility}/{device_id}/capture/*` for evidence lifecycle.
* **511-teams-notification requires 8 source files.** main.rs, config.rs, alert.rs, teams.rs, adaptive_card.rs, dedup.rs, health.rs, otel.rs. Plus Cargo.toml, Dockerfile, Helm chart, docker-compose.yaml.
* **Leak detection blueprint excludes 6 optional components.** No PostgreSQL, Managed Redis, Azure ML, AI Foundry, AKS, or Fabric RTI in Phase 1. SSE connector always enabled, EventHub dataflow always enabled.
* **Dedup and rate limiting are critical for Teams integration.** Per-camera (30s window) + global (10/min) rate limits prevent notification flooding. DedupCache with sliding window eviction by event_id.
* **Webhook URL must be stored in Key Vault.** Retrieved via AIO Secret Sync at startup. Secret name: `teams-webhook-url`. Rotation handled by Key Vault policy.
* **Latency budget: < 5s end-to-end (P95).** SSE→MQTT (50ms) + Inference (250ms) + Teams webhook (2s) + overhead. Ring buffer in 503 ensures pre-event video is captured regardless of processing latency.
* **Three-phase implementation plan.** Parker (511 service, parallel), Ripley (blueprint + IaC, parallel with Parker), Lambert (tests, sequential after Parker/Ripley). Dallas reviews all outputs.

📌 Team update (2025-07-17): 511-teams-notification implemented with raw TcpListener health (no axum), composite dedup key (camera_id, event_id) — decided by Parker
📌 Team update (2025-07-17): leak-detection Terraform blueprint created with 14 modules; SSE connector hardcoded enabled, EventHub dataflows enabled — decided by Ripley

### 2026-02-17: Architecture Revision — 509 Stays, 511 → Azure Logic App

* **509-sse-connector retained.** Analysis of AIO portal connector types confirmed SSE and Media are separate native connectors serving different data types. 508-media-connector handles RTSP binary data (snapshots, video clips, streams). 509-sse-connector handles structured JSON events via Server-Sent Events. ALERT_DLQC events are structured JSON with 18+ fields — SSE is the correct protocol. 508 cannot replace 509; they are complementary.
* **511-teams-notification replaced with Azure Logic App.** The 130-messaging dataflow already routes ALERT_DLQC events from edge MQTT broker to Event Hub. A Logic App triggered by Event Hub eliminates the need for an edge Rust container. Benefits: no container build/deploy/maintain cycle, built-in retry and Teams connector, Azure Monitor integration, managed identity auth to Key Vault and Event Hub. The 511 directory is retained but no longer deployed.
* **Design proposal updated (Revision 2).** All 12 sections updated: system context diagram moves notification to cloud tier, edge fan-out reduced from 3 to 2 subscribers, §3.2 rewritten from Rust microservice design to Logic App workflow design, MQTT topic hierarchy removes `notifications/` tree, security updated for Logic App managed identity, observability updated for Azure Monitor/Logic App run history, implementation plan simplified from 13 Rust tasks to 8 IaC tasks, delegation shifts from Parker to Ripley, risk register updated for Logic App-specific risks.
* **Key simplification metric.** Original §3.2 was ~350 lines of Rust code samples and service architecture. Revised §3.2 is ~120 lines of Logic App workflow definition and deployment options. Fewer moving parts on the edge.

📌 Team update (2025-07-25): Logic App notification component created at 045-notification — decided by Ripley
