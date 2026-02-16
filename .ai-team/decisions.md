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

