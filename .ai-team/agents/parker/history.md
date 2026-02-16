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
