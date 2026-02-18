# History — Parker

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)
- **Stack:** Terraform, Bicep, Rust, Azure IoT Operations, Azure Arc, K3s
- **Goal:** Build the edge-side leak detection service: capture inference events, produce metadata, deliver Teams notifications.
- **Existing Rust services:** src/500-application/ contains 500-basic-inference, 501-rust-telemetry, 502-rust-http-connector, 503-media-capture-service
- **Conventions:** Follow existing Rust patterns and Cargo workspace structure (Cargo.toml at root)

## Learnings

### 2026-02-16: 511-teams-notification implementation

**Files created** (all under `src/500-application/511-teams-notification/`):

| File | Purpose |
|------|---------|
| `services/teams-notification/Cargo.toml` | Package manifest — mirrors 501 AIO SDK deps, adds reqwest (rustls-tls), serde, tracing/otel stack |
| `services/teams-notification/src/main.rs` | Entry point — AIO SDK MqttConnectionSettingsBuilder → Session → telemetry::Receiver → tokio::select! loop with health endpoint |
| `services/teams-notification/src/config.rs` | Environment-based config: TEAMS_WEBHOOK_URL (required), TOPIC, HEALTH_PORT, retry/dedup/rate-limit params |
| `services/teams-notification/src/alert.rs` | ALERT_DLQC schema (22 fields), GeoLocation, AlertSeverity enum, PayloadSerialize impl for AIO SDK |
| `services/teams-notification/src/teams.rs` | TeamsClient — reqwest HTTP client with token-bucket rate limiter, exponential backoff retry, 429 Retry-After handling |
| `services/teams-notification/src/adaptive_card.rs` | Adaptive Card JSON builder — severity-coded header, alert details FactSet, environmental FactSet, map link action |
| `services/teams-notification/src/dedup.rs` | DedupCache — in-memory HashMap keyed on (camera_id, event_id) with configurable TTL eviction |
| `services/teams-notification/src/health.rs` | Minimal HTTP health server via tokio::net::TcpListener — /healthz and /readyz endpoints, no framework dependency |
| `services/teams-notification/src/otel.rs` | OpenTelemetry setup — OTLP exporter, W3C TraceContext propagation, handle_receive_trace for distributed tracing |
| `services/teams-notification/Dockerfile` | Multi-stage build — Azure Linux 3.0 builder with Rust 1.86, dep caching layer, non-root runtime |
| `docker-compose.yaml` | Local dev compose — mosquitto broker + teams-notification service with all env vars |
| `README.md` | Service documentation — architecture, env vars table, build/deploy, ALERT_DLQC schema reference |

**AIO SDK patterns used:**
- `MqttConnectionSettingsBuilder::from_environment()` → `SessionOptionsBuilder` → `Session::new()` (identical to 501 receiver)
- `ApplicationContextBuilder::default().build()` for protocol context
- `telemetry::receiver::OptionsBuilder` with topic pattern and auto_ack
- `telemetry::Receiver<AlertPayload, SessionManagedClient>` — custom PayloadSerialize impl wrapping AlertDlqc
- `tokio::select!` for concurrent session, processing loop, and health endpoint
- W3C TraceContext propagation via custom_user_data extraction (same pattern as 501 otel.rs)

**Key decisions:**
- Used raw `tokio::net::TcpListener` for health endpoints instead of axum to avoid adding a framework dependency for two trivial routes
- Dedup key is `(camera_id, event_id)` tuple rather than `event_id` alone — prevents cross-camera collisions
- Token-bucket rate limiter in TeamsClient struct using atomics — refills proportionally over time
- PayloadSerialize impl deserializes directly to AlertDlqc via serde, skipping intermediate Value parsing
- No axum dependency despite design proposal mention — health endpoint is minimal enough to avoid it

📌 Team update (2025-07-17): leak-detection Terraform blueprint created with 14 modules; SSE connector hardcoded enabled, EventHub dataflows enabled, AKS/AzureML excluded — decided by Ripley
📌 Team update (2025-07-16): DLQ policy is DROP — rate-limited alerts are silently dropped, no DLQ required. Parker's `TeamsError::RateLimited` return path in `send_card()` is confirmed correct — decided by Dallas (Carlos directed)
📌 Team update (2025-07-24): 511-teams-notification Rust service is superseded by Azure Logic App (cloud-side). 13 Parker Rust tasks replaced with 8 Ripley IaC tasks. Existing 511 Rust code retained but no longer part of architecture. Disposition deferred to Carlos — decided by Dallas
📌 Team update (2025-07-24): 509-sse-connector confirmed retained — complementary to 508 Media Connector (SSE for structured JSON, Media for RTSP binary). No changes needed — decided by Dallas
📌 Team update (2025-07-25): Logic App notification component created at 045-notification — decided by Ripley

### 2025-07-25: 507-ai-inference deep technical analysis

**Scope:** Full audit of 507-ai-inference and cross-comparison with all 11 application directories.

**Key findings:**

- **Build chain:** Multi-stage Dockerfile on CBL-Mariner 2.0 (SHA-pinned), Rust 1.88.0, dual backend via `BACKEND` build arg (`onnx` → ONNX Runtime 1.17.0, `candle` → pure Rust). Docker Compose context is `./services` so both crates are in scope. Binary name: `ai-edge-mqtt-publisher`.
- **Deployment:** Kustomize-based (only app not using Helm). Base resources: Deployment, Service (8080 metrics, 8081 health), ServiceAccount, PVC (10Gi local-path). Overlay sets namespace `azure-iot-operations` and patches image via JSON Patch.
- **Auth:** Projected SAT volume (audience `aio-internal`, 3600s expiry) + AIO CA trust bundle ConfigMap. Connects to `aio-broker.azure-iot-operations:18883` with TLS.
- **Scripts:** `services/ai-edge-inference/scripts/deploy.sh` (334 lines) — full build→push→deploy pipeline. `charts/gen-patch.sh` (60 lines) — Kustomize patch generator.
- **CI/CD:** `Application-Builder.ps1` (shared) detects `docker-compose.yaml` and builds. Pipeline builds and pushes but does NOT auto-deploy to edge.
- **Model configs:** `industrial-safety.yaml` includes "leak" as a class label — confirms alignment with leak detection use case.

**Gaps identified:**

| Gap | Severity |
|-----|----------|
| Not referenced in leak-detection blueprint `main.tf` | High |
| Health probes commented out in `deployment.yaml` | High |
| CBL-Mariner 2.0 (old) vs Azure Linux 3.0 (current standard) | Medium |
| Version-pinned OS packages that will break on updates | Medium |
| Kustomize instead of Helm (inconsistent with other apps) | Medium |
| Hardcoded `acrmodules01.azurecr.io` in deployment.yaml | Low |
| No automated model provisioning | Medium |
| Placeholder models in `resources/models/` | Low |

**Report:** `.ai-team/agents/parker/507-analysis-report.md`
**Decision proposal:** `.ai-team/decisions/inbox/507-inference-automation-gaps.md`

📌 Team update (2025-07-15): 507 deployment automation — Hybrid approach recommended (CI/CD for Docker build/push, Terraform for Kustomize deploy via Arc proxy). Blueprint gains `should_deploy_ai_inference` feature flag — decided by Dallas
📌 Team update (2025-07-15): Infrastructure analysis confirms `terraform_data` + `local-exec` for builds, `helm_release` for Helm deploys, ACR registry endpoint must be enabled — decided by Ripley
