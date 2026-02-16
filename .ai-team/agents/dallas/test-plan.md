# Leak Detection Accelerator — Test Plan

**Author:** Lambert (Tester)
**Status:** PROPOSED
**Scope:** 511-teams-notification Rust service + leak-detection Terraform blueprint

---

## 1. Unit Test Specifications — Rust Service

### 1.1 alert.rs — ALERT_DLQC Deserialization

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-01 | Deserialize valid ALERT_DLQC with all 22 fields | Complete JSON with all fields populated | `AlertDlqc` struct with all fields matching input values | P0 |
| UT-02 | Severity: confidence 0 → Low | `confidence_level: 0` | `AlertSeverity::Low`, label `"LOW"`, color `"Good"` | P0 |
| UT-03 | Severity: confidence 39 → Low | `confidence_level: 39` | `AlertSeverity::Low` | P0 |
| UT-04 | Severity: confidence 40 → Medium | `confidence_level: 40` | `AlertSeverity::Medium`, label `"MEDIUM"`, color `"Accent"` | P0 |
| UT-05 | Severity: confidence 59 → Medium | `confidence_level: 59` | `AlertSeverity::Medium` | P0 |
| UT-06 | Severity: confidence 60 → High | `confidence_level: 60` | `AlertSeverity::High`, label `"HIGH"`, color `"Warning"` | P0 |
| UT-07 | Severity: confidence 79 → High | `confidence_level: 79` | `AlertSeverity::High` | P0 |
| UT-08 | Severity: confidence 80 → Critical | `confidence_level: 80` | `AlertSeverity::Critical`, label `"CRITICAL"`, color `"Attention"` | P0 |
| UT-09 | Severity: confidence 100 → Critical | `confidence_level: 100` | `AlertSeverity::Critical` | P0 |
| UT-10 | Invalid JSON payload | `{"not_valid": true}` | `DeserializationError::InvalidPayload` | P0 |
| UT-11 | Empty payload | `[]` (empty bytes) | `DeserializationError::InvalidPayload` | P1 |
| UT-12 | Wrong content type | Valid payload, content_type `"text/plain"` | `DeserializationError::UnsupportedContentType` | P1 |
| UT-13 | Null content type accepted | Valid payload, content_type `None` | Successful deserialization | P1 |
| UT-14 | AlertSeverity Display trait | Each severity variant | `format!()` produces `"CRITICAL"`, `"HIGH"`, `"MEDIUM"`, `"LOW"` | P2 |
| UT-15 | AlertPayload round-trip | Serialize then deserialize | Identical `AlertDlqc` values after round-trip | P1 |
| UT-16 | Negative geo-coordinates | `longitude: -171.21, latitude: -64.08` | Accepted without error | P1 |
| UT-17 | Zero-value numerics | `flow_rate: 0.0, mass: 0.0, humidity: 0` | Accepted without error | P2 |

### 1.2 dedup.rs — Deduplication Cache

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-20 | First alert not duplicate | Alert with unique `(camera_id, event_id)` | `is_duplicate` returns `false` | P0 |
| UT-21 | Same alert within window is duplicate | Same `(camera_id, event_id)` twice, no delay | Second call returns `true` | P0 |
| UT-22 | Same alert after window expiry | Same `(camera_id, event_id)`, wait > `window_secs` | Second call returns `false` | P0 |
| UT-23 | Cross-camera isolation — same event_id | `(camera_id=1, event_id=100)` then `(camera_id=2, event_id=100)` | Both return `false` (not duplicates of each other) | P0 |
| UT-24 | Cross-event isolation — same camera_id | `(camera_id=1, event_id=100)` then `(camera_id=1, event_id=101)` | Both return `false` | P1 |
| UT-25 | Eviction cleans expired entries | Insert N entries, advance past window, call `is_duplicate` | Internal `seen` map has 0 expired entries after eviction | P1 |
| UT-26 | Many unique keys no collision | Insert 1000 unique `(camera_id, event_id)` pairs | All return `false` | P2 |
| UT-27 | Window of 0 seconds | `DedupCache::new(0)` | Every call returns `false` (immediate expiry) | P2 |

### 1.3 adaptive_card.rs — Adaptive Card Builder

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-30 | Card structure for Critical alert | Alert with `confidence_level: 95` | Container style `"Attention"`, title contains `"CRITICAL"` | P0 |
| UT-31 | Card structure for High alert | Alert with `confidence_level: 70` | Container style `"Warning"`, title contains `"HIGH"` | P0 |
| UT-32 | Card structure for Medium alert | Alert with `confidence_level: 50` | Container style `"Accent"`, title contains `"MEDIUM"` | P0 |
| UT-33 | Card structure for Low alert | Alert with `confidence_level: 20` | Container style `"Good"`, title contains `"LOW"` | P0 |
| UT-34 | Google Maps link | `leak_location: { lat: 64.55, lon: 35.78 }` | Action URL `"https://www.google.com/maps?q=64.5500,35.7800"` (4 decimal places) | P0 |
| UT-35 | Card schema version | Any alert | `content.$schema` = `"http://adaptivecards.io/schemas/adaptive-card.json"`, `version` = `"1.4"` | P1 |
| UT-36 | Card content type | Any alert | `attachments[0].contentType` = `"application/vnd.microsoft.card.adaptive"` | P1 |
| UT-37 | FactSet field count | Any alert | Primary FactSet has 8 facts (Camera ID, Confidence, Flow Rate, Mass, Leak Location, Camera Location, Camera Orientation, Depression Angle) | P1 |
| UT-38 | Environmental FactSet | Any alert | Environmental FactSet has 3 facts (Temperature, Wind, Humidity) | P1 |
| UT-39 | Timestamp text block | Alert with `timestamp: 1705339210000` | TextBlock contains `"Timestamp: 1705339210000"` | P2 |
| UT-40 | Message text block | Alert with `message: "leak"` | TextBlock with `"leak"` rendered | P1 |
| UT-41 | Flow rate formatting | `flow_rate: 0.714703` | Fact value `"0.71 g/s"` (2 decimal places) | P1 |
| UT-42 | Degree symbol in coordinates | Any alert | Location values contain `°` (U+00B0) | P2 |

### 1.4 teams.rs — Webhook Client

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-50 | Successful send (200) | Mock server returns 200 | `send_card` returns `Ok(())` | P0 |
| UT-51 | Retry on 500 with backoff | Mock server returns 500 twice then 200; `max_retries: 3` | `Ok(())` after 3 calls; delays match exponential backoff (500ms, 1000ms) | P0 |
| UT-52 | Max retries exceeded | Mock server returns 500 for all attempts; `max_retries: 3` | `Err(TeamsError::MaxRetriesExceeded)` | P0 |
| UT-53 | 429 with Retry-After header | Mock server returns 429 with `Retry-After: 2` then 200 | Waits 2 seconds, then retries; `Ok(())` | P0 |
| UT-54 | 429 without Retry-After header | Mock server returns 429 without header; `retry_delay_ms: 500` | Falls back to `500/1000 = 0` seconds wait (default) | P1 |
| UT-55 | 4xx non-429 drops message | Mock server returns 400 | `Err(TeamsError::HttpError("HTTP 400 Bad Request"))` — no retry | P0 |
| UT-56 | Rate limiter: token available | Tokens > 0 | `try_acquire` returns `true`, `send_card` proceeds | P0 |
| UT-57 | Rate limiter: tokens exhausted | Tokens = 0, no time for refill | `send_card` returns `Err(TeamsError::RateLimited)` | P0 |
| UT-58 | Rate limiter: token refill over time | Exhaust all tokens, wait for refill interval | `try_acquire` returns `true` after sufficient elapsed time | P1 |
| UT-59 | Rate limiter: max_tokens cap | Wait long enough to exceed max_tokens | `tokens` never exceeds `max_tokens` | P1 |
| UT-60 | Connection error triggers retry | Mock server unreachable | Retries with backoff, then `Err(TeamsError::MaxRetriesExceeded)` | P1 |
| UT-61 | HTTP timeout | Mock server delays > 10s | Treated as connection error, retries | P2 |

### 1.5 config.rs — Configuration

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-70 | Missing TEAMS_WEBHOOK_URL panics | Env without `TEAMS_WEBHOOK_URL` | `expect()` panic | P0 |
| UT-71 | Default TOPIC value | No `TOPIC` env var | `"alerts/+/+/leak/dlqc"` | P0 |
| UT-72 | Default HEALTH_PORT | No `HEALTH_PORT` env var | `8080` | P1 |
| UT-73 | Default MAX_RETRIES | No `MAX_RETRIES` env var | `3` | P1 |
| UT-74 | Default RETRY_DELAY_MS | No `RETRY_DELAY_MS` env var | `500` | P1 |
| UT-75 | Default DEDUP_WINDOW_SECS | No `DEDUP_WINDOW_SECS` env var | `60` | P1 |
| UT-76 | Default RATE_LIMIT_PER_MIN | No `RATE_LIMIT_PER_MIN` env var | `10` | P1 |
| UT-77 | Custom TOPIC override | `TOPIC=custom/topic/#` | Config.topic = `"custom/topic/#"` | P1 |
| UT-78 | Invalid HEALTH_PORT panics | `HEALTH_PORT=notanumber` | `expect()` panic | P2 |
| UT-79 | Custom rate limit | `RATE_LIMIT_PER_MIN=30` | Config.rate_limit_per_min = `30` | P2 |

### 1.6 health.rs — Health Endpoints

| ID | Test Case | Input | Expected Result | Priority |
|----|-----------|-------|-----------------|----------|
| UT-80 | GET /healthz returns 200 | HTTP GET `http://localhost:{port}/healthz` | Status 200, body `{"status":"healthy"}` | P0 |
| UT-81 | GET /readyz returns 200 | HTTP GET `http://localhost:{port}/readyz` | Status 200, body `{"status":"ready"}` | P0 |
| UT-82 | Unknown path returns 404 | HTTP GET `http://localhost:{port}/unknown` | Status 404 | P1 |
| UT-83 | Concurrent requests handled | Multiple parallel GET /healthz | All return 200 (spawned per-connection) | P2 |

---

## 2. Integration Test Scenarios

| ID | Scenario | Setup | Steps | Expected Result | Priority |
|----|----------|-------|-------|-----------------|----------|
| IT-01 | MQTT → Teams end-to-end | Local MQTT broker (mosquitto), mock Teams webhook server, service running | 1. Publish valid ALERT_DLQC JSON to `alerts/plant-alpha/leak-cam-01/leak/dlqc` on local broker 2. Wait up to 3s | Mock webhook receives POST with Adaptive Card JSON containing correct severity, event_id, camera_id, and geo-coordinates | P0 |
| IT-02 | Dedup suppresses duplicate | Same as IT-01 | 1. Publish identical ALERT_DLQC twice within 60s window 2. Wait 3s | Mock webhook receives exactly 1 POST | P0 |
| IT-03 | Dedup allows after window | Same as IT-01 with `DEDUP_WINDOW_SECS=2` | 1. Publish ALERT_DLQC 2. Wait 3s 3. Publish same alert again | Mock webhook receives 2 POSTs | P1 |
| IT-04 | Rate limit throttling | Same as IT-01 with `RATE_LIMIT_PER_MIN=2` | 1. Publish 5 distinct alerts in rapid succession | Mock webhook receives exactly 2 POSTs; remaining 3 logged as rate-limited | P0 |
| IT-05 | Retry on webhook failure | Mock server returns 500 twice then 200 | 1. Publish valid ALERT_DLQC | Mock webhook receives 3 total requests; service logs show retries; final result is success | P0 |
| IT-06 | Health liveness | Service running with active MQTT connection | `GET /healthz` | 200 OK, `{"status":"healthy"}` | P0 |
| IT-07 | Health readiness | Service running with active MQTT connection | `GET /readyz` | 200 OK, `{"status":"ready"}` | P0 |
| IT-08 | Cross-camera events | Same as IT-01 | 1. Publish ALERT_DLQC with `camera_id=1, event_id=100` 2. Publish ALERT_DLQC with `camera_id=2, event_id=100` | Mock webhook receives 2 POSTs (different cameras, same event_id) | P0 |
| IT-09 | Malformed JSON resilience | Same as IT-01 | 1. Publish invalid JSON to alert topic 2. Publish valid ALERT_DLQC | Service logs deserialization error for first message; processes second message and sends webhook | P1 |
| IT-10 | Service shutdown | Same as IT-01 | 1. Start service 2. Send SIGTERM | Service logs shutdown messages, exits cleanly with code 0 | P1 |
| IT-11 | OpenTelemetry trace propagation | OTLP collector + local broker | 1. Publish ALERT_DLQC with W3C traceparent header 2. Check collector | Span `teams-notification/receive-alert` appears with correct parent trace ID | P2 |

### Integration Test Environment

```text
docker-compose test stack:
  - mosquitto (MQTT broker, no TLS for testing)
  - teams-notification service (built from source)
  - mock-webhook (simple HTTP server recording requests)
  - optional: OTLP collector (for IT-11)

Environment variables for service:
  TEAMS_WEBHOOK_URL=http://mock-webhook:8081/webhook
  TOPIC=alerts/+/+/leak/dlqc
  HEALTH_PORT=8080
  MAX_RETRIES=3
  RETRY_DELAY_MS=100
  DEDUP_WINDOW_SECS=60
  RATE_LIMIT_PER_MIN=10

AIO MQTT connection env vars:
  AIO_MQ_DIRECT_HOST=mosquitto
  AIO_MQ_DIRECT_PORT=1883
  AIO_MQ_PROTOCOL=mqtt
```

---

## 3. Terraform Validation Checklist

| ID | Check | Command / Method | Expected Result | Priority |
|----|-------|------------------|-----------------|----------|
| TF-01 | `terraform validate` passes | `cd blueprints/leak-detection/terraform && terraform init && terraform validate` | `Success! The configuration is valid.` | P0 |
| TF-02 | `tflint` passes | `npm run tflint-fix -- blueprints/leak-detection/terraform` | No errors | P0 |
| TF-03 | Module source paths resolve | `terraform init` completes without source errors | All 14 module sources found at relative paths | P0 |
| TF-04 | `terraform plan` with minimal vars | `terraform plan -var-file=ci/terraform/min.tfvars` (or equivalent) | Plan generates without errors; resource count > 0 | P0 |
| TF-05 | Variables match component interfaces | Manual audit: each module call in `main.tf` passes only variables defined in the component's `variables.tf` | No undefined variable errors in plan | P0 |
| TF-06 | Outputs reference valid module outputs | `terraform validate` + review `outputs.tf` | All output references resolve to existing module outputs | P1 |
| TF-07 | tfvars example applies without errors | `terraform plan -var-file=leak-detection-assets.tfvars.example -var="environment=dev" -var="location=eastus2" -var="resource_prefix=leak"` | Plan generates without variable type errors | P0 |
| TF-08 | SSE connector hardcoded enabled | Review `main.tf` → `edge_iot_ops` module | `should_enable_akri_sse_connector = true` (not variable-driven) | P1 |
| TF-09 | EventHub dataflows enabled | Review `main.tf` → `edge_messaging` module | `should_create_eventhub_dataflows = true` | P1 |
| TF-10 | EventGrid dataflows disabled | Review `main.tf` → `edge_messaging` module | `should_create_eventgrid_dataflows = false` | P1 |
| TF-11 | Asset device schema matches 111-assets | Compare `namespaced_devices` type in `variables.tf` with `src/100-edge/111-assets/terraform/variables.tf` | Type structure is identical | P0 |
| TF-12 | Asset definitions use event_groups | Review `leak-detection-assets.tfvars.example` | Contains `event_groups` with HEARTBEAT, ALERT_DLQC, ALERT events | P0 |
| TF-13 | ALERT_DLQC event topic pattern | Review tfvars example | Topic matches `alerts/{facility}/{device_id}/leak/dlqc` | P0 |
| TF-14 | ALERT_DLQC QoS | Review tfvars example | QoS is `"Qos1"` (at-least-once delivery) | P1 |
| TF-15 | HEARTBEAT QoS | Review tfvars example | QoS is `"Qos0"` (best-effort) | P2 |
| TF-16 | Module dependency chain | Review `depends_on` in `main.tf` | `edge_arc_extensions` → `edge_cncf_cluster`, `edge_iot_ops` → `edge_arc_extensions`, `edge_assets` → `edge_iot_ops` | P1 |
| TF-17 | No excluded modules present | Review `main.tf` | No AKS, AzureML, AI Foundry, Fabric, or PostgreSQL modules | P1 |
| TF-18 | `versions.tf` exists with provider constraints | File presence and content | Contains `azurerm`, `azapi`, `azuread` providers with version constraints | P1 |
| TF-19 | Blueprint tag applied | Review `cloud_resource_group` module | `tags = { blueprint = "leak-detection" }` | P2 |

---

## 4. Security Verification

| ID | Check | Method | Expected Result | Priority |
|----|-------|--------|-----------------|----------|
| SEC-01 | reqwest uses rustls-tls | Review `Cargo.toml` | `reqwest` has `features = ["json", "rustls-tls"]` and `default-features = false` | P0 |
| SEC-02 | No OpenSSL dependency | `cargo tree -i openssl` or `cargo tree -i openssl-sys` | Neither crate appears in dependency tree | P0 |
| SEC-03 | Webhook URL from env (Key Vault via Secret Sync) | Review `config.rs` | `TEAMS_WEBHOOK_URL` read from `std::env::var`, not hardcoded | P0 |
| SEC-04 | No secrets in log output | Review all `tracing::info!`, `warn!`, `error!` calls | No webhook URL, tokens, or credentials in log format strings | P0 |
| SEC-05 | No secrets in Adaptive Card | Review `adaptive_card.rs` | Card JSON contains only alert data fields, no webhook URLs or auth tokens | P0 |
| SEC-06 | mTLS for MQTT | Review Helm values and AIO configuration | `MqttConnectionSettingsBuilder::from_environment()` uses AIO-provided TLS settings; no `should_create_anonymous_broker_listener = true` in prod | P0 |
| SEC-07 | SAT authentication for MQTT | Review Kubernetes ServiceAccount | teams-notification pod uses a dedicated ServiceAccount with SAT token mount | P1 |
| SEC-08 | BrokerAuthorization topic restriction | Review AIO BrokerAuthorization resources | 511-teams-notification restricted to subscribe `alerts/#`, publish `notifications/#` | P1 |
| SEC-09 | Anonymous broker listener default | Review `variables.tf` | `should_create_anonymous_broker_listener` defaults to `false` | P0 |
| SEC-10 | No hardcoded credentials in Terraform | Review all `.tf` files | No API keys, passwords, or webhook URLs in Terraform source | P1 |
| SEC-11 | Container image from trusted registry | Review Dockerfile and Helm values | Image built from `rust:slim` or equivalent; pulled from ACR or MCR | P2 |
| SEC-12 | Release binary stripped | Review `Cargo.toml` | `[profile.release] strip = true` | P2 |

---

## 5. Performance Criteria

| ID | Criterion | Target | Measurement Method | Priority |
|----|-----------|--------|-------------------|----------|
| PERF-01 | Alert-to-notification latency | < 3 seconds (P95) | Timestamp delta: `ALERT_DLQC.timestamp` vs. Teams webhook request timestamp; or OpenTelemetry span duration for `teams-notification/receive-alert` | P0 |
| PERF-02 | Dedup cache memory bounded | Entries evicted after `DEDUP_WINDOW_SECS` | Observe `seen` map size under sustained load; verify entries are cleaned by `evict_expired` | P1 |
| PERF-03 | Rate limiter queuing behavior | Alerts exceeding rate limit are dropped (not queued) | Send burst > `RATE_LIMIT_PER_MIN`; verify `Err(TeamsError::RateLimited)` for excess; no unbounded queue growth | P1 |
| PERF-04 | Single-threaded runtime efficiency | Service processes alerts on `current_thread` runtime | `#[tokio::main(flavor = "current_thread")]` in `main.rs`; no thread pool overhead | P2 |
| PERF-05 | HTTP client connection reuse | Persistent HTTP connections to Teams webhook | `reqwest::Client` reused across calls (singleton in `TeamsClient`) | P2 |
| PERF-06 | Webhook timeout | 10 seconds max per request | `reqwest::Client::builder().timeout(Duration::from_secs(10))` in `teams.rs` | P1 |

**Implementation note:** PERF-03 reveals that the current rate limiter drops alerts when tokens are exhausted (`TeamsError::RateLimited`). The design proposal §3.2.6 specifies rate limiting; the implementation does not queue. This is a known behavior difference — dropped alerts are logged but not retried.

---

## 6. Acceptance Criteria

| ID | Criterion | Derived From | Verification | Priority |
|----|-----------|-------------|--------------|----------|
| AC-01 | ALERT_DLQC received on MQTT triggers Teams notification within 3s | Design §2.2 latency budget | IT-01 + PERF-01 | P0 |
| AC-02 | Severity correctly derived from confidence_level | Design §4 severity table | UT-02 through UT-09 | P0 |
| AC-03 | Adaptive Card renders in Teams with correct formatting | Design §3.2.5 | UT-30 through UT-42 + manual Teams channel verification | P0 |
| AC-04 | Duplicate alerts within dedup window suppressed | Design §3.2.6 | IT-02, UT-20 through UT-27 | P0 |
| AC-05 | Service retries on Teams webhook failures | Design §3.2.7 error table | UT-51 through UT-55, IT-05 | P0 |
| AC-06 | Health and readiness endpoints report correct status | Design §3.2.8 | UT-80 through UT-83, IT-06, IT-07 | P0 |
| AC-07 | Blueprint deploys complete leak detection infrastructure | Design §3.4 | TF-01 through TF-19 | P0 |
| AC-08 | Rate limiting prevents Teams API abuse | Design §3.2.6 | UT-56 through UT-59, IT-04 | P1 |
| AC-09 | Service handles malformed input without crashing | Resilience requirement | IT-09, UT-10 through UT-13 | P1 |
| AC-10 | Asset definitions match canonical topic hierarchy | Design §5 topic architecture | TF-12 through TF-15 | P1 |
| AC-11 | No secrets exposed in logs or card output | Design §6 security | SEC-04, SEC-05 | P0 |
| AC-12 | OpenTelemetry traces propagated | Design §7 observability | IT-11 | P2 |

---

## 7. Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| Rate limiter atomics | `AtomicU32` operations in `try_acquire` are Relaxed ordering — potential for slight over/under-count under extreme concurrency | Single-threaded runtime (`current_thread`) eliminates real concurrency; acceptable for this use case |
| Dedup window accuracy | `Instant::now()` used for TTL — no test-time control without `tokio::time::pause()` | Integration tests should use short windows (1–2s) to verify expiry behavior |
| Health endpoint simplicity | Raw `TcpListener` parses only `starts_with("GET /healthz")` — no full HTTP parsing | HTTP/1.1 clients and Kubernetes probes send well-formed requests; edge case of malformed requests returns 404 |
| Token bucket refill precision | Integer division for refill calculation may cause token starvation at very low rates | Acceptable with `rate_limit_per_min >= 1`; documented behavior |
| Webhook URL rotation | Service reads `TEAMS_WEBHOOK_URL` once at startup | Pod restart required after Key Vault secret rotation; AIO Secret Sync handles this via pod restart triggers |

---

## 8. Test Execution Summary

| Category | Count | P0 | P1 | P2 |
|----------|-------|----|----|-----|
| Unit Tests (alert.rs) | 17 | 10 | 5 | 2 |
| Unit Tests (dedup.rs) | 8 | 4 | 2 | 2 |
| Unit Tests (adaptive_card.rs) | 13 | 5 | 5 | 3 |
| Unit Tests (teams.rs) | 12 | 6 | 4 | 2 |
| Unit Tests (config.rs) | 10 | 2 | 6 | 2 |
| Unit Tests (health.rs) | 4 | 2 | 1 | 1 |
| Integration Tests | 11 | 6 | 3 | 2 |
| Terraform Checks | 19 | 7 | 9 | 3 |
| Security Checks | 12 | 6 | 4 | 2 |
| Performance Criteria | 6 | 1 | 3 | 2 |
| Acceptance Criteria | 12 | 7 | 3 | 2 |
| **Total** | **124** | **56** | **45** | **23** |
