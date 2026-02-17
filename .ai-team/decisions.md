# Decisions

> Team decisions that all agents must respect. Append-only — never edit existing entries.

### 2025-07-16: Repository analysis — architecture direction for Leak Detection Accelerator

**By:** Dallas (Lead)

**What:** After exhaustive analysis of the Edge AI repository (30+ components, 11 application services, 16+ infrastructure modules, blueprints), the following architecture direction was established:

1. Adopt the existing SSE connector (509) as the primary leak event source — ALERT_DLQC events already defined
2. Implement 511-teams-notification using the 501 AIO SDK pattern (Rust, MqttConnectionSettingsBuilder → Session → telemetry::Receiver)
3. Wire 507-ai-inference for leak detection models (dual-backend ONNX/Candle)
4. Use 503-media-capture-service for evidence capture triggered by ALERT_DLQC MQTT events
5. Reuse 130-messaging dataflows for edge-to-cloud transport (EventHub and EventGrid)
6. Create a dedicated leak-detection blueprint composing the relevant subset of components

**Why:** ~80% of infrastructure already exists. The SSE connector's ALERT_DLQC event type proves this use case was anticipated. 511-teams-notification scaffold is the single largest gap.

**Delegation:** Parker → 511 service, Ripley → Blueprint/IaC, Lambert → Test plan

**Status:** PROPOSED

---

### 2025-07-16: Formal design proposal for Leak Detection Accelerator

**By:** Dallas (Lead)

**What:** Produced a 12-section design proposal at `.ai-team/agents/dallas/design-proposal.md` specifying: full architecture with data flow diagrams, detailed 511-teams-notification design (Rust code samples, Adaptive Card format, dedup/rate-limiting, health endpoints), reuse plan for 5 existing components, ALERT_DLQC canonical event schema (18 fields), MQTT topic architecture, leak detection Terraform blueprint composition, asset definitions, security/observability patterns, three-phase implementation plan with delegation matrix, risk register (9 risks), and end-to-end verification guide.

**Why:** Parker, Ripley, and Lambert need a concrete, actionable specification to begin parallel implementation. Eliminates ambiguity with exact schemas, code patterns, file paths, and acceptance criteria.

**Status:** PROPOSED

---

### 2026-02-16: 511-teams-notification implementation

**By:** Parker (App Dev)

**What:** Implemented the complete 511-teams-notification Rust microservice. Used raw `tokio::net::TcpListener` for health endpoints instead of axum. Dedup key is `(camera_id, event_id)` tuple instead of `event_id` alone. No `azure_iot_operations_services` crate needed. Removed `futures`, `async-trait`, `chrono`, `uuid` deps from design proposal since they aren't used.

**Why:** Axum adds unnecessary binary size and dependency surface for two trivial HTTP routes. Composite dedup key prevents cross-camera event_id collisions. Unused dependencies violate minimal dependency conventions.

**Status:** PROPOSED

---

### 2025-07-17: Created leak-detection Terraform blueprint

**By:** Ripley (Infra Dev)

**What:** Created a complete Terraform blueprint at `blueprints/leak-detection/terraform/` composing 14 existing component modules into a deployment-ready stamp. Files: versions.tf, main.tf, variables.tf, outputs.tf, leak-detection-assets.tfvars.example, README.md. Modules: resource_group, networking, security_identity, observability, data, messaging, vm_host, acr, cncf_cluster, arc_extensions, iot_ops, assets, edge_observability, edge_messaging. Excluded: AKS, AzureML, AI Foundry, Fabric.

**Why:** Design proposal §3.4 specifies a leak detection blueprint reusing existing IaC. SSE connector always enabled (hardcoded). EventGrid dataflows disabled — only EventHub routes telemetry to cloud.

**Status:** PROPOSED

---

### 2025-07-16: DLQ policy — DROP rate-limited alerts

**By:** Dallas (resolving Lambert's test-plan question)

**What:** Rate-limited alerts are silently dropped. No dead-letter queue (DLQ) or persistence layer is required. The current `TeamsError::RateLimited` return path in `send_card()` is the intended behavior.

**Why:** Carlos directed "drop" when presented with the DLQ question. The leak-detection notification service is advisory — missed alerts are acceptable given the token-bucket rate limiter refills within 60 s. Adding a DLQ would increase infrastructure cost and complexity without meaningful safety benefit for this use case.

**Status:** ACCEPTED

---

### 2025-07-17: Lambert test plan for leak detection accelerator

**By:** Lambert (Tester)

**What:** Comprehensive test plan created covering 511-teams-notification Rust service and leak-detection Terraform blueprint. 124 test cases across unit tests, integration tests, Terraform validation, security, performance, and acceptance criteria.

**Artifacts:** `.ai-team/agents/dallas/test-plan.md`

**Embedded decisions:**
1. Rate limiter drop behavior documented as PERF-03 — validates current drop behavior as intended, not a defect.
2. Integration test stack uses docker-compose — local mosquitto + mock webhook for reproducible E2E testing.
3. Terraform tests restricted to plan-only — per project conventions.

**Open questions resolved:** DLQ question answered by Dallas (DROP policy, see above).

**Status:** PROPOSED

---

### 2026-02-17: 509 SSE Connector retained — complementary to 508 Media Connector

**By:** Dallas (Lead)

**What:** After architecture review, the 509-sse-connector is confirmed as a required component. SSE and Media are separate AIO portal connector types serving different data types:

* **509-sse-connector** uses `Microsoft.SSE` endpoint type for structured JSON event data (ALERT_DLQC with 18+ fields: confidence, flow rate, mass, location, weather)
* **508-media-connector** uses the Media connector type for RTSP binary data (snapshots, video clips, camera streams)

These are two of five distinct AIO connector types (ONVIF, Media, HTTP/REST, SSE, MQTT) and cannot substitute for each other. The leak detection pipeline requires both: SSE for event ingestion and Media for evidence capture.

**Why:** There was a question about whether 509 duplicated the purpose of 508. Analysis of the AIO connector framework and the data types involved shows they are complementary. ALERT_DLQC events are structured JSON — SSE is the correct ingestion protocol. RTSP binary streams cannot carry structured event metadata, and SSE cannot carry binary video data.

**Impact:** No changes required. 509 remains in the architecture, blueprint, and design proposal as originally specified. Design proposal §3.1.1 updated with a "Protocol distinction" paragraph documenting this rationale.

**Status:** PROPOSED

---

### 2026-02-17: 511-teams-notification replaced with Azure Logic App

**By:** Dallas (Lead)

**What:** The `511-teams-notification` Rust microservice is replaced by an Azure Logic App (Consumption or Standard) running in the cloud. The Logic App is triggered by Event Hub (which already receives ALERT_DLQC events via the 130-messaging dataflow) and posts Adaptive Cards to Microsoft Teams via Incoming Webhook.

**Why:** The 130-messaging dataflow already routes ALERT_DLQC events from the edge MQTT broker to Event Hub. A cloud-side Logic App subscribes to that Event Hub — no new edge-to-cloud plumbing is needed. Benefits:

* No edge container to build, deploy, or maintain (eliminates Rust build pipeline, Dockerfile, Helm chart, ACR image)
* Built-in retry and error handling via Logic App retry policies
* Native Teams connector with webhook support
* Azure Monitor integration (run history, diagnostic logs, alerts out of the box)
* Managed identity authentication to Event Hub and Key Vault
* Simpler operational model — fewer moving parts on the edge

**Architecture changes:**

* Design proposal updated to Revision 2 (all 12 sections modified)
* Edge fan-out reduced from 3 to 2 subscribers (503-media-capture and 130-messaging only)
* §3.2 rewritten from Rust microservice design (~350 lines) to Logic App workflow design (~120 lines)
* MQTT topic hierarchy: `notifications/` tree removed
* Security: Logic App system-assigned managed identity replaces edge SAT-based auth; two new RBAC roles added (Event Hubs Data Receiver, Key Vault Secrets User)
* Observability: edge OTel spans for 511 removed; replaced with Azure Monitor / Logic App run history
* Implementation plan Phase 1: 13 Parker Rust tasks replaced with 8 Ripley IaC tasks
* Delegation: Logic App work assigned to Ripley (IaC), not Parker (App Dev)

**Disposition of `src/500-application/511-teams-notification/`:** The existing directory and implemented Rust service are retained but no longer part of the architecture. No blueprint module references it. Disposition deferred to Carlos.

**Status:** PROPOSED

---

### 2025-07-25: Logic App notification component created at 045-notification

**By:** Ripley
**What:** Created src/000-cloud/045-notification/terraform/ with 6 files (main.tf, variables.core.tf, variables.deps.tf, variables.tf, outputs.tf, versions.tf) plus CI config. Updated leak-detection blueprint (main.tf, variables.tf, outputs.tf) to include cloud_notification module.
**Why:** Implements §3.2 of the design proposal — Azure Logic App for Teams leak detection notifications, replacing the previously planned 511 Rust service. Logic App uses SystemAssigned managed identity with Event Hubs Data Receiver and Key Vault Secrets User roles.
