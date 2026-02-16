# Leak Detection Accelerator — Design Proposal

**Author:** Dallas (Lead Architect)
**Date:** 2026-02-16
**Status:** PROPOSED
**Reviewer:** Carlos Sardo

---

## 1. Executive Summary

The Leak Detection Accelerator delivers a production-ready, edge-native solution for detecting and responding to gas and liquid leaks in Oil & Gas and Energy environments. It combines real-time visual and sensor-based inference at the edge with automated alerting, evidence capture, and cloud-side analytics — all running on Azure IoT Operations over K3s with Azure Arc.

**Value proposition:** This accelerator reduces mean time to detection (MTTD) from minutes to sub-second, captures forensic video evidence automatically, and ensures operations teams are notified in Microsoft Teams within seconds of a leak event. It does this by composing existing, proven components from this repository — approximately 80% of the required infrastructure already exists.

**Core delivery (Milestone 1):**

1. Camera/sensor → edge AI inference → leak event generation
2. Leak event → parallel fan-out to Media Capture, Edge-to-Cloud messaging, and Teams notification
3. Cloud-side event archival, dashboards, and analytics

**What's new:**

- `511-teams-notification`: Rust microservice (the only greenfield application code)
- Leak detection asset definitions in `111-assets`
- A purpose-built `leak-detection` blueprint
- Configuration tuning of existing components (509, 507, 503, 130)

---

## 2. Architecture Overview

### 2.1 System Context Diagram

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              EDGE (K3s + Azure Arc)                            │
│                                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐                  │
│  │ Analytics     │SSE │ 509 SSE      │MQTT│ AIO MQTT Broker   │                 │
│  │ Camera /      ├───►│ Connector    ├───►│ (aio-broker)      │                 │
│  │ Sensor Array  │    │              │    │                    │                 │
│  └──────────────┘    └──────────────┘    └────────┬───────────┘                 │
│                                                   │                             │
│                                          ┌────────▼───────────┐                 │
│                                          │ 507 AI Inference    │                 │
│                                          │ (ONNX / Candle)     │                 │
│                                          │ Leak Detection Model│                 │
│                                          └────────┬───────────┘                 │
│                                                   │                             │
│                                          ALERT_DLQC published                   │
│                                          to leak alert topic                    │
│                                                   │                             │
│                          ┌────────────────────────┼──────────────────────┐      │
│                          │                        │                      │      │
│                 ┌────────▼────────┐    ┌──────────▼─────────┐  ┌────────▼─────┐│
│                 │ 503 Media       │    │ 130 Edge Messaging  │  │ 511 Teams    ││
│                 │ Capture Service │    │ (Dataflows)         │  │ Notification ││
│                 │ RTSP → ACSA     │    │ MQTT → Event Hub    │  │ MQTT → Teams ││
│                 └────────┬────────┘    └──────────┬─────────┘  └──────────────┘│
│                          │                        │                             │
└──────────────────────────┼────────────────────────┼─────────────────────────────┘
                           │                        │
                    ┌──────▼──────┐          ┌──────▼──────────┐
                    │ Azure Blob  │          │ Azure Event Hub  │
                    │ Storage     │          │ / Event Grid     │
                    │ (video)     │          │ (leak events)    │
                    └─────────────┘          └────────┬────────┘
                                                      │
                                             ┌────────▼────────┐
                                             │ Cloud Analytics  │
                                             │ Dashboards (020) │
                                             │ Log Analytics    │
                                             │ Grafana          │
                                             └─────────────────┘
```

### 2.2 Edge Data Flow

The edge data flow follows a strict sequential pipeline with a terminal fan-out:

```text
1. INGEST:   Camera SSE stream → 509-sse-connector → AIO MQTT Broker
             Topic: events/{facility}/{device_id}/camera/raw

2. ANALYZE:  AIO MQTT Broker → 507-ai-inference (subscriber)
             Topic: events/{facility}/{device_id}/camera/raw
             Model: leak-detection-v1 (ONNX or Candle backend)

3. DETECT:   507-ai-inference → AIO MQTT Broker
             Topic: alerts/{facility}/{device_id}/leak/dlqc
             Payload: ALERT_DLQC JSON (see §4)

4. FAN-OUT:  Three independent subscribers on the leak alert topic:
             a) 503-media-capture-service → captures RTSP evidence
             b) 130-messaging dataflow   → routes to Event Hub
             c) 511-teams-notification   → sends Teams Adaptive Card
```

**Latency budget (target):**

| Stage | Target | Notes |
|-------|--------|-------|
| SSE → MQTT ingestion | < 50ms | Network + connector overhead |
| MQTT → Inference result | < 250ms | Candle: 155ms, ONNX: 220ms typical |
| ALERT_DLQC → Teams notification | < 2s | Webhook HTTP call + retry |
| ALERT_DLQC → Media capture start | < 500ms | Ring buffer already recording |
| ALERT_DLQC → Event Hub delivery | < 1s | Dataflow passthrough |
| **Total: Camera → Teams** | **< 3s** | End-to-end detection + notification |

### 2.3 Cloud Data Flow

```text
Event Hub (leak events)
    ├─→ Azure Stream Analytics / Functions → PostgreSQL (035) time-series storage
    ├─→ Log Analytics Workspace (020) → KQL dashboards
    └─→ Grafana (020) → operational dashboards and alerting rules

Blob Storage (video evidence)
    └─→ Indexed by event_id for forensic retrieval
```

Cloud-side processing is out of scope for Milestone 1 but the pipeline is already wired — the 130-messaging dataflows and 503-media-capture ACSA sync handle delivery.

### 2.4 Component Interaction Map

```text
Component                Source Path                                     Role
─────────────────────────────────────────────────────────────────────────────────────
509-sse-connector        src/500-application/509-sse-connector/          Event source (SSE → MQTT)
507-ai-inference         src/500-application/507-ai-inference/           Leak detection model host
503-media-capture        src/500-application/503-media-capture-service/  Evidence capture (RTSP → ACSA)
511-teams-notification   src/500-application/511-teams-notification/     Teams alerting (NEW)
110-iot-ops              src/100-edge/110-iot-ops/                       AIO platform (MQTT broker, Akri)
111-assets               src/100-edge/111-assets/                       Device Registry definitions
130-messaging            src/100-edge/130-messaging/                     Edge-to-cloud data transport
020-observability        src/000-cloud/020-observability/                Dashboards and monitoring
010-security-identity    src/000-cloud/010-security-identity/            Key Vault, identities, RBAC
030-data                 src/000-cloud/030-data/                         Schema Registry, ADR, Storage
040-messaging            src/000-cloud/040-messaging/                    Event Hub / Event Grid (cloud)
```

---

## 3. Component Design

### 3.1 Existing Components (Reuse)

#### 3.1.1 — 509-sse-connector (Event Source)

**What it does:** Maintains persistent SSE connections to analytics cameras and forwards events to AIO MQTT Broker. Already defines `ALERT_DLQC` event type with full leak detection fields.

**Source:** `src/500-application/509-sse-connector/`

**Configuration changes for leak detection:**

- Deploy with `should_enable_akri_sse_connector = true` in the blueprint
- Configure SSE endpoint URL to point at leak detection cameras
- Map event topics in asset definitions:
  - `HEARTBEAT` → `events/{facility}/{device_id}/camera/heartbeat`
  - `ALERT` → `alerts/{facility}/{device_id}/leak/basic`
  - `ALERT_DLQC` → `alerts/{facility}/{device_id}/leak/dlqc`

**No code changes required.** Configuration via Terraform asset definitions and Akri connector settings.

#### 3.1.2 — 507-ai-inference (Model Host)

**What it does:** Dual-backend inference engine (ONNX Runtime 220ms / Candle 155ms) that subscribes to MQTT topics, runs inference, and publishes results.

**Source:** `src/500-application/507-ai-inference/services/ai-edge-inference/`

**Configuration for leak detection:**

- Deploy a trained leak detection model (ONNX format) to the model directory
- Set `MODEL_DIRECTORY` to point at the leak detection model
- Configure MQTT subscription topic to match camera raw data topic
- Set `TOPIC_PREFIX` to `alerts/{facility}/{device_id}/leak` so inference results publish to the correct alert topic
- The `TopicRouter` (in `src/500-application/507-ai-inference/services/ai-edge-inference/src/topic_router.rs`) already supports priority-based routing based on inference confidence

**No code changes required.** Model deployment + environment configuration only.

#### 3.1.3 — 503-media-capture-service (Evidence Capture)

**What it does:** In-memory ring buffer for continuous RTSP stream capture. Triggered by MQTT events to extract and save video segments. Cloud sync via ACSA to Blob Storage.

**Source:** `src/500-application/503-media-capture-service/`

**Configuration for leak detection:**

- Subscribe to `alerts/{facility}/+/leak/dlqc` for capture triggers
- Configure RTSP stream URLs matching the leak detection cameras
- Set capture window: 30 seconds pre-event (ring buffer) + 60 seconds post-event
- ACSA configuration for cloud sync to a `leak-evidence` blob container
- Video filename pattern: `{facility}_{device_id}_{event_id}_{timestamp}.mp4`

**No code changes required.** MQTT topic subscription + ACSA configuration.

#### 3.1.4 — 130-messaging (Edge-to-Cloud Dataflows)

**What it does:** AIO Dataflows for routing MQTT messages to cloud endpoints (Event Hub, Event Grid, Fabric RTI).

**Source:** `src/100-edge/130-messaging/terraform/`

**Configuration for leak detection:**

- Use the EventHub dataflow module (`modules/eventhub/main.tf`): source `alerts/#/leak/dlqc` → destination Event Hub
- Set `should_create_eventhub_dataflows = true` in the blueprint
- MQTT source topic filter: `alerts/+/+/leak/dlqc`
- Data transformation: PassThrough (the ALERT_DLQC schema is already well-structured)

**No code changes required.** Terraform variable configuration.

#### 3.1.5 — 110-iot-ops (AIO Platform)

**What it does:** Deploys the full Azure IoT Operations stack: MQTT Broker, Dataflow engine, Akri connector framework, Device Registry integration.

**Source:** `src/100-edge/110-iot-ops/`

**Configuration for leak detection:**

- `should_enable_akri_sse_connector = true` — enables the SSE connector for camera integration
- Optional: `should_enable_akri_media_connector = true` for additional RTSP camera discovery
- Optional: `should_enable_akri_onvif_connector = true` for ONVIF IP camera management
- `should_create_anonymous_broker_listener = false` in production (mTLS enforced)
- Registry endpoints configured for ACR pull of leak detection container images

**No code changes required.** Feature flags in blueprint variables.

---

### 3.2 New Implementation: 511-teams-notification

**Source:** `src/500-application/511-teams-notification/`
**Status:** Empty scaffold — full implementation required

#### 3.2.1 Service Architecture

A Rust microservice following the canonical AIO SDK pattern from `501-rust-telemetry`. The service:

1. Connects to the AIO MQTT Broker using `MqttConnectionSettingsBuilder::from_environment()`
2. Subscribes to leak alert topics (`alerts/+/+/leak/dlqc`)
3. Deserializes `ALERT_DLQC` payloads
4. Formats Microsoft Teams Adaptive Cards with severity-coded alert information
5. Posts to Teams Incoming Webhook URLs via HTTPS
6. Handles rate limiting, deduplication, and retry logic
7. Exposes health and readiness HTTP endpoints
8. Publishes OpenTelemetry traces for end-to-end observability

#### 3.2.2 Directory Structure

```text
src/500-application/511-teams-notification/
├── README.md
├── docker-compose.yaml
├── charts/
│   └── teams-notification/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           └── service.yaml
└── services/
    └── teams-notification/
        ├── Cargo.toml
        ├── Dockerfile
        └── src/
            ├── main.rs
            ├── config.rs
            ├── alert.rs          # ALERT_DLQC deserialization
            ├── teams.rs          # Teams webhook client
            ├── adaptive_card.rs  # Adaptive Card builder
            ├── dedup.rs          # Deduplication cache
            ├── health.rs         # Health endpoint
            └── otel.rs           # OpenTelemetry setup
```

#### 3.2.3 MQTT Subscription Pattern

```rust
use azure_iot_operations_mqtt::{
    session::{Session, SessionManagedClient, SessionOptionsBuilder},
    MqttConnectionSettingsBuilder,
};
use azure_iot_operations_protocol::{
    application::ApplicationContextBuilder,
    telemetry,
};

const DEFAULT_TOPIC: &str = "alerts/+/+/leak/dlqc";

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    setup_otel_tracing("teams-notification");

    let config = Config::from_env();

    let connection_settings = MqttConnectionSettingsBuilder::from_environment()
        .unwrap()
        .build()
        .unwrap();

    let session_options = SessionOptionsBuilder::default()
        .connection_settings(connection_settings)
        .build()?;

    let session = Session::new(session_options)?;
    let exit_handle = session.create_exit_handle();

    let application_context = ApplicationContextBuilder::default().build()?;

    let receiver_options = telemetry::receiver::OptionsBuilder::default()
        .topic_pattern(&config.topic)
        .auto_ack(true)
        .build()?;

    let mut receiver: telemetry::Receiver<AlertPayload, _> = telemetry::Receiver::new(
        application_context.clone(),
        session.create_managed_client(),
        receiver_options,
    )?;

    let teams_client = TeamsClient::new(&config);
    let dedup_cache = DedupCache::new(config.dedup_window_secs);
    let health_service = HealthService::new(config.health_port);

    tokio::select! {
        r = alert_processing_loop(&mut receiver, &teams_client, &dedup_cache) => {
            r.map_err(|e| e as Box<dyn std::error::Error>)?
        },
        r = session.run() => r?,
        r = health_service.serve() => r?,
    }

    receiver.shutdown().await?;
    exit_handle.try_exit().await?;
    Ok(())
}
```

#### 3.2.4 Alert Payload Deserialization

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertDlqc {
    #[serde(rename = "type")]
    pub event_type: String,
    pub timestamp: u64,
    pub message: String,
    pub event_id: u64,
    pub camera_id: u32,
    pub leak_location: GeoLocation,
    pub camera_location: GeoLocation,
    pub flow_rate: f64,
    pub unit: String,
    pub mass: f64,
    pub mass_unit: String,
    pub confidence_level: u32,
    pub camera_orientation: u32,
    pub depression_angle: u32,
    pub wind_speed: f64,
    pub wind_speed_unit: String,
    pub wind_direction: u32,
    pub temperature: f64,
    pub temperature_unit: String,
    pub humidity: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeoLocation {
    pub longitude: f64,
    pub latitude: f64,
}

impl AlertDlqc {
    pub fn severity(&self) -> AlertSeverity {
        match self.confidence_level {
            80..=100 => AlertSeverity::Critical,
            60..=79  => AlertSeverity::High,
            40..=59  => AlertSeverity::Medium,
            _        => AlertSeverity::Low,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AlertSeverity {
    Critical,
    High,
    Medium,
    Low,
}

impl AlertSeverity {
    pub fn color(&self) -> &'static str {
        match self {
            AlertSeverity::Critical => "Attention",
            AlertSeverity::High     => "Warning",
            AlertSeverity::Medium   => "Accent",
            AlertSeverity::Low      => "Good",
        }
    }

    pub fn label(&self) -> &'static str {
        match self {
            AlertSeverity::Critical => "CRITICAL",
            AlertSeverity::High     => "HIGH",
            AlertSeverity::Medium   => "MEDIUM",
            AlertSeverity::Low      => "LOW",
        }
    }
}
```

#### 3.2.5 Teams Webhook Integration (Adaptive Card)

The service posts to a Microsoft Teams Incoming Webhook URL using the Adaptive Card schema:

```rust
use reqwest::Client;
use serde_json::json;

pub struct TeamsClient {
    http_client: Client,
    webhook_url: String,
    max_retries: u32,
    retry_delay_ms: u64,
}

impl TeamsClient {
    pub fn new(config: &Config) -> Self {
        Self {
            http_client: Client::builder()
                .timeout(std::time::Duration::from_secs(10))
                .build()
                .expect("HTTP client creation"),
            webhook_url: config.teams_webhook_url.clone(),
            max_retries: config.max_retries,
            retry_delay_ms: config.retry_delay_ms,
        }
    }

    pub async fn send_alert(&self, alert: &AlertDlqc) -> Result<(), TeamsError> {
        let card = self.build_adaptive_card(alert);

        for attempt in 0..=self.max_retries {
            match self.http_client
                .post(&self.webhook_url)
                .header("Content-Type", "application/json")
                .json(&card)
                .send()
                .await
            {
                Ok(response) if response.status().is_success() => return Ok(()),
                Ok(response) if response.status() == 429 => {
                    // Rate limited — respect Retry-After header
                    let retry_after = response
                        .headers()
                        .get("Retry-After")
                        .and_then(|v| v.to_str().ok())
                        .and_then(|v| v.parse::<u64>().ok())
                        .unwrap_or(self.retry_delay_ms / 1000);
                    tokio::time::sleep(
                        std::time::Duration::from_secs(retry_after)
                    ).await;
                    continue;
                }
                Ok(response) => {
                    tracing::warn!(
                        status = %response.status(),
                        attempt,
                        "Teams webhook returned non-success status"
                    );
                }
                Err(e) => {
                    tracing::warn!(error = %e, attempt, "Teams webhook request failed");
                }
            }
            if attempt < self.max_retries {
                let backoff = self.retry_delay_ms * 2u64.pow(attempt);
                tokio::time::sleep(std::time::Duration::from_millis(backoff)).await;
            }
        }
        Err(TeamsError::MaxRetriesExceeded)
    }

    fn build_adaptive_card(&self, alert: &AlertDlqc) -> serde_json::Value {
        let severity = alert.severity();
        json!({
            "type": "message",
            "attachments": [{
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": null,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.4",
                    "body": [
                        {
                            "type": "Container",
                            "style": severity.color(),
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "text": format!(
                                        "🚨 LEAK DETECTED — {} — Event #{}",
                                        severity.label(),
                                        alert.event_id
                                    ),
                                    "weight": "Bolder",
                                    "size": "Large",
                                    "wrap": true
                                }
                            ]
                        },
                        {
                            "type": "FactSet",
                            "facts": [
                                {"title": "Camera ID", "value": format!("{}", alert.camera_id)},
                                {"title": "Confidence", "value": format!("{}%", alert.confidence_level)},
                                {"title": "Flow Rate", "value": format!("{:.2} {}", alert.flow_rate, alert.unit)},
                                {"title": "Mass", "value": format!("{:.2} {}", alert.mass, alert.mass_unit)},
                                {"title": "Location", "value": format!(
                                    "{:.4}°, {:.4}°",
                                    alert.leak_location.latitude,
                                    alert.leak_location.longitude
                                )},
                                {"title": "Temperature", "value": format!(
                                    "{:.1}° {}",
                                    alert.temperature,
                                    alert.temperature_unit
                                )},
                                {"title": "Wind", "value": format!(
                                    "{:.1} {} at {}°",
                                    alert.wind_speed,
                                    alert.wind_speed_unit,
                                    alert.wind_direction
                                )},
                                {"title": "Humidity", "value": format!("{}%", alert.humidity)},
                                {"title": "Timestamp", "value": format!("{}", alert.timestamp)}
                            ]
                        }
                    ]
                }
            }]
        })
    }
}
```

#### 3.2.6 Rate Limiting and Deduplication

```rust
use std::collections::HashMap;
use std::time::{Duration, Instant};

pub struct DedupCache {
    seen: HashMap<u64, Instant>,
    window: Duration,
}

impl DedupCache {
    pub fn new(window_secs: u64) -> Self {
        Self {
            seen: HashMap::new(),
            window: Duration::from_secs(window_secs),
        }
    }

    /// Returns true if this event_id has NOT been seen within the dedup window.
    pub fn check_and_insert(&mut self, event_id: u64) -> bool {
        self.evict_expired();
        if self.seen.contains_key(&event_id) {
            false
        } else {
            self.seen.insert(event_id, Instant::now());
            true
        }
    }

    fn evict_expired(&mut self) {
        let cutoff = Instant::now() - self.window;
        self.seen.retain(|_, ts| *ts > cutoff);
    }
}
```

Rate limiting strategy:
- **Per-camera rate limit:** Maximum 1 notification per camera per 30 seconds (configurable via `RATE_LIMIT_WINDOW_SECS`)
- **Global rate limit:** Maximum 10 notifications per minute across all cameras (configurable via `GLOBAL_RATE_LIMIT_PER_MIN`)
- **Dedup window:** Default 60 seconds — duplicate `event_id` values within this window are silently dropped

#### 3.2.7 Error Handling and Retry

| Error | Behavior |
|-------|----------|
| MQTT connection lost | AIO SDK auto-reconnect with exponential backoff |
| Teams webhook 429 (rate limited) | Respect `Retry-After` header, then retry |
| Teams webhook 5xx | Exponential backoff: 500ms, 1s, 2s, 4s (max 3 retries) |
| Teams webhook 4xx (non-429) | Log error, drop message (bad request = bug in card format) |
| Deserialization failure | Log warning with payload, skip message, continue processing |
| Health endpoint failure | Log error, service still processes alerts (health is non-critical) |

#### 3.2.8 Health Endpoints

```text
GET /health     → 200 OK { "status": "healthy", "uptime_secs": N }
GET /readiness  → 200 OK { "status": "ready", "mqtt_connected": true, "last_alert_secs_ago": N }
```

Implemented with `axum` (lightweight, tokio-native). Kubernetes liveness and readiness probes point here.

#### 3.2.9 Configuration (Environment Variables)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TEAMS_WEBHOOK_URL` | Yes | — | Teams Incoming Webhook URL |
| `TOPIC` | No | `alerts/+/+/leak/dlqc` | MQTT topic pattern |
| `HEALTH_PORT` | No | `8080` | Health endpoint port |
| `MAX_RETRIES` | No | `3` | Max webhook retry attempts |
| `RETRY_DELAY_MS` | No | `500` | Base retry delay (exponential) |
| `DEDUP_WINDOW_SECS` | No | `60` | Event deduplication window |
| `RATE_LIMIT_WINDOW_SECS` | No | `30` | Per-camera rate limit window |
| `GLOBAL_RATE_LIMIT_PER_MIN` | No | `10` | Max alerts/minute globally |
| `RUST_LOG` | No | `info` | Log level |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | No | — | OTLP endpoint for tracing |

All AIO MQTT connection variables (`AIO_MQ_*`, `AIO_BROKER_*`) are handled by `MqttConnectionSettingsBuilder::from_environment()`.

#### 3.2.10 Cargo.toml Dependencies

```toml
[package]
name = "teams-notification"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.14.0", features = ["full"] }
azure_iot_operations_protocol = { version = "0.9.0", registry = "aio-sdks" }
azure_iot_operations_mqtt = { version = "0.9.0", registry = "aio-sdks" }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
reqwest = { version = "0.12", features = ["json", "rustls-tls"], default-features = false }
tracing = { version = "0.1", features = ["std", "attributes"] }
tracing-subscriber = { version = "0.3", features = ["env-filter", "registry", "std", "fmt"] }
tracing-opentelemetry = "0.30"
opentelemetry = { version = "0.29" }
opentelemetry_sdk = { version = "0.29", features = ["rt-tokio"] }
opentelemetry-otlp = { version = "0.29", features = ["grpc-tonic"] }
axum = "0.8"

[profile.release]
strip = true
```

---

### 3.3 New Implementation: Leak Detection Asset Definitions

**Target:** `src/100-edge/111-assets/`
**Action:** Define leak detection camera assets using the namespaced Device Registry model

The asset definitions follow the existing pattern in `variables.tf` (namespaced_assets with event_groups). These are provided as Terraform variable values in the blueprint.

#### Namespaced Device (SSE Camera Connector)

```terraform
namespaced_devices = [
  {
    name    = "leak-detection-camera"
    enabled = true
    endpoints = {
      outbound = { assigned = {} }
      inbound = {
        "sse-leak-camera-endpoint" = {
          endpoint_type = "Microsoft.SSE"
          address       = "http://analytics-camera:8080/camera-events"
          authentication = {
            method = "Anonymous"
          }
        }
      }
    }
  }
]
```

#### Namespaced Asset (Leak Detection Events)

```terraform
namespaced_assets = [
  {
    name         = "leak-detection-asset"
    display_name = "Leak Detection Analytics Camera"
    device_ref = {
      device_name   = "leak-detection-camera"
      endpoint_name = "sse-leak-camera-endpoint"
    }
    description     = "Analytics camera asset for leak detection with DLQC events"
    manufacturer    = "Site Analytics Corp"
    model           = "LAC-5000"
    enabled         = true
    attributes      = {
      facility    = "plant-alpha"
      zone        = "pipeline-section-3"
      asset_class = "leak-detection"
    }
    event_groups = [
      {
        name = "leak_detection_events"
        events = [
          {
            name        = "HEARTBEAT"
            data_source = "ns=2;s=HeartbeatEvent"
            destinations = [
              {
                target = "Mqtt"
                configuration = {
                  topic  = "events/plant-alpha/leak-cam-01/camera/heartbeat"
                  retain = "Never"
                  qos    = "Qos0"
                }
              }
            ]
          },
          {
            name        = "ALERT_DLQC"
            data_source = "ns=2;s=AlertDlqcEvent"
            destinations = [
              {
                target = "Mqtt"
                configuration = {
                  topic  = "alerts/plant-alpha/leak-cam-01/leak/dlqc"
                  retain = "Never"
                  qos    = "Qos1"
                }
              }
            ]
          },
          {
            name        = "ALERT"
            data_source = "ns=2;s=AlertEvent"
            destinations = [
              {
                target = "Mqtt"
                configuration = {
                  topic  = "alerts/plant-alpha/leak-cam-01/leak/basic"
                  retain = "Never"
                  qos    = "Qos1"
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

---

### 3.4 New Implementation: Leak Detection Blueprint

**Target:** `blueprints/leak-detection/terraform/`

A purpose-built blueprint composing the minimum set of components for a leak detection deployment. Follows the same composition pattern as `blueprints/full-single-node-cluster/terraform/main.tf`.

#### Blueprint Module Composition

```terraform
/**
 * # Leak Detection Blueprint
 *
 * Deploys a single-node Azure IoT Operations cluster optimized for
 * leak detection in Oil & Gas / Energy environments.
 */

# ── Cloud Foundation ──────────────────────────────────────────

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"
  # ... standard vars
}

module "cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_vm_host" {
  source = "../../../src/000-cloud/051-vm-host/terraform"
  # ... standard vars
  resource_group     = module.cloud_resource_group.resource_group
  virtual_network    = module.cloud_networking.virtual_network
}

module "cloud_acr" {
  source = "../../../src/000-cloud/060-acr/terraform"
  # ... standard vars
  resource_group = module.cloud_resource_group.resource_group
}

# ── Edge Foundation ───────────────────────────────────────────

module "edge_cncf_cluster" {
  source     = "../../../src/100-edge/100-cncf-cluster/terraform"
  depends_on = [module.cloud_vm_host]
  # ... standard vars
  resource_group          = module.cloud_resource_group.resource_group
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp       = module.cloud_security_identity.arc_onboarding_sp
  cluster_server_machine  = module.cloud_vm_host.virtual_machines[0]
  key_vault               = module.cloud_security_identity.key_vault
}

module "edge_arc_extensions" {
  source     = "../../../src/100-edge/109-arc-extensions/terraform"
  depends_on = [module.edge_cncf_cluster]
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
}

module "edge_iot_ops" {
  source     = "../../../src/100-edge/110-iot-ops/terraform"
  depends_on = [module.edge_arc_extensions]

  adr_schema_registry   = module.cloud_data.schema_registry
  adr_namespace         = module.cloud_data.adr_namespace
  resource_group        = module.cloud_resource_group.resource_group
  aio_identity          = module.cloud_security_identity.aio_identity
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cloud_security_identity.key_vault
  secret_sync_identity  = module.cloud_security_identity.secret_sync_identity

  # Leak detection: enable SSE connector for analytics cameras
  should_enable_akri_sse_connector = true
  registry_endpoints               = local.combined_registry_endpoints
}

# ── Leak Detection Specific ──────────────────────────────────

module "edge_assets" {
  source     = "../../../src/100-edge/111-assets/terraform"
  depends_on = [module.edge_iot_ops]

  location           = var.location
  resource_group     = module.cloud_resource_group.resource_group
  custom_location_id = module.edge_iot_ops.custom_locations.id
  adr_namespace      = module.cloud_data.adr_namespace

  namespaced_devices = var.namespaced_devices
  namespaced_assets  = var.namespaced_assets
}

module "edge_observability" {
  source     = "../../../src/100-edge/120-observability/terraform"
  depends_on = [module.edge_iot_ops]
  # ... standard vars
  resource_group        = module.cloud_resource_group.resource_group
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
}

module "edge_messaging" {
  source     = "../../../src/100-edge/130-messaging/terraform"
  depends_on = [module.edge_iot_ops]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_custom_locations = module.edge_iot_ops.custom_locations
  aio_dataflow_profile = module.edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.edge_iot_ops.aio_instance
  aio_identity         = module.cloud_security_identity.aio_identity
  eventhub             = module.cloud_messaging.eventhubs[0]
  adr_namespace        = module.cloud_data.adr_namespace

  should_create_eventhub_dataflows = true
}
```

#### Key Differences from full-single-node-cluster

| Feature | full-single-node-cluster | leak-detection |
|---------|--------------------------|----------------|
| PostgreSQL | Optional | Excluded (Phase 1) |
| Managed Redis | Optional | Excluded (Phase 1) |
| Azure ML | Optional | Excluded (Phase 1) |
| AI Foundry | Optional | Excluded (Phase 1) |
| AKS (cloud) | Optional | Excluded |
| VPN Gateway | Optional | Optional |
| SSE Connector | Configurable | Always enabled |
| Asset definitions | Generic OPC-UA | Leak detection camera assets |
| Dataflows | All types configurable | EventHub always enabled |

---

## 4. ALERT_DLQC Event Schema

This is the **canonical contract** between all components. Every agent must use this schema exactly.

**Source of truth:** `src/500-application/509-sse-connector/services/sse-server/events_simulator.py` (line 125)

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

### Field Reference

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `type` | string | — | Always `"ALERT_DLQC"` |
| `timestamp` | u64 | ms | Unix epoch in milliseconds |
| `message` | string | — | Alert category (always `"leak"` for this event type) |
| `event_id` | u64 | — | Monotonically increasing event identifier |
| `camera_id` | u32 | — | Camera identifier (1–N per facility) |
| `leak_location.longitude` | f64 | degrees | Leak geo-location longitude (-180 to 180) |
| `leak_location.latitude` | f64 | degrees | Leak geo-location latitude (-90 to 90) |
| `camera_location.longitude` | f64 | degrees | Camera geo-location longitude |
| `camera_location.latitude` | f64 | degrees | Camera geo-location latitude |
| `flow_rate` | f64 | g/s | Estimated leak flow rate (grams per second) |
| `unit` | string | — | Flow rate unit label (always `"g/s"`) |
| `mass` | f64 | kg | Estimated total leaked mass |
| `mass_unit` | string | — | Mass unit label (always `"kg"`) |
| `confidence_level` | u32 | % | Detection confidence (0–100) |
| `camera_orientation` | u32 | degrees | Camera azimuth heading (0–360) |
| `depression_angle` | u32 | degrees | Camera depression angle (0–90) |
| `wind_speed` | f64 | m/h | Wind speed at detection site |
| `wind_speed_unit` | string | — | Wind speed unit label |
| `wind_direction` | u32 | degrees | Wind direction (0–360, meteorological) |
| `temperature` | f64 | °F | Ambient temperature |
| `temperature_unit` | string | — | Temperature unit label |
| `humidity` | u32 | % | Relative humidity (0–100) |

### Severity Derivation

Components derive severity from `confidence_level`:

| Range | Severity | Teams Card Color |
|-------|----------|-----------------|
| 80–100 | CRITICAL | Attention (red) |
| 60–79 | HIGH | Warning (orange) |
| 40–59 | MEDIUM | Accent (blue) |
| 0–39 | LOW | Good (green) |

---

## 5. MQTT Topic Architecture

### Topic Hierarchy

```text
edge-ai/
├── events/                                           # Non-alert operational events
│   └── {facility}/
│       └── {device_id}/
│           └── camera/
│               ├── heartbeat                         # HEARTBEAT events
│               ├── analytics-enabled                 # ANALYTICS_ENABLED events
│               └── analytics-disabled                # ANALYTICS_DISABLED events
│
├── alerts/                                           # Alert events (higher QoS)
│   └── {facility}/
│       └── {device_id}/
│           └── leak/
│               ├── basic                             # ALERT events (basic leak)
│               └── dlqc                              # ALERT_DLQC (detailed leak)
│
├── notifications/                                    # Notification status
│   └── {facility}/
│       └── {device_id}/
│           └── teams/
│               ├── sent                              # Notification delivery confirmations
│               └── failed                            # Notification failures
│
├── media/                                            # Media capture lifecycle
│   └── {facility}/
│       └── {device_id}/
│           └── capture/
│               ├── started                           # Capture initiated
│               ├── completed                         # Capture saved
│               └── synced                            # Uploaded to cloud (ACSA)
│
└── inference/                                        # AI inference results
    └── {facility}/
        └── {device_id}/
            └── vision/
                └── leak-detection/                   # Inference output before thresholding
                    ├── result                        # Full inference result
                    └── metrics                       # Performance metrics
```

### QoS Policy

| Topic Pattern | QoS | Rationale |
|---------------|-----|-----------|
| `events/+/+/camera/heartbeat` | 0 | Best-effort, periodic, loss-tolerant |
| `alerts/+/+/leak/dlqc` | 1 | At-least-once: critical safety data |
| `alerts/+/+/leak/basic` | 1 | At-least-once |
| `notifications/+/+/teams/*` | 0 | Informational, loss-tolerant |
| `media/+/+/capture/*` | 1 | At-least-once: evidence chain integrity |
| `inference/+/+/vision/leak-detection/*` | 0 | High-volume metrics |

### Subscriber Map

| Component | Subscribes To | Publishes To |
|-----------|---------------|--------------|
| 509-sse-connector | External SSE endpoint | `events/{f}/{d}/camera/*`, `alerts/{f}/{d}/leak/*` |
| 507-ai-inference | `events/{f}/{d}/camera/raw` | `alerts/{f}/{d}/leak/dlqc`, `inference/{f}/{d}/vision/*` |
| 511-teams-notification | `alerts/+/+/leak/dlqc` | `notifications/{f}/{d}/teams/sent\|failed` |
| 503-media-capture | `alerts/+/+/leak/dlqc` | `media/{f}/{d}/capture/*` |
| 130-messaging (dataflow) | `alerts/+/+/leak/dlqc` | → Event Hub (cloud) |

---

## 6. Security Considerations

### Edge-to-Cloud Authentication

- **AIO MQTT Broker:** mTLS for all service-to-broker connections (Kubernetes SAT tokens for authentication, no anonymous listeners in production)
- **Event Hub dataflow:** User-assigned Managed Identity (UAMI) for Kafka-protocol authentication — already configured in 130-messaging
- **ACSA cloud sync:** Managed Identity for Blob Storage access — already configured in 503-media-capture

### Webhook Security (Teams)

- **Webhook URL storage:** The Teams Incoming Webhook URL must be stored in Azure Key Vault, retrieved at startup via AIO Secret Sync
- **Secret name:** `teams-webhook-url`
- **Key Vault reference:** The 010-security-identity component provisions the Key Vault; the blueprint wires it to AIO secret sync
- **HTTPS only:** `reqwest` client enforces HTTPS for webhook calls (use `rustls-tls` backend, no OpenSSL dependency)

### MQTT TLS/mTLS

- **Broker listener:** TLS with the AIO-provisioned CA certificate
- **Client authentication:** Kubernetes Service Account Token (SAT) authentication, bound to a dedicated ServiceAccount for the teams-notification pod
- **Topic authorization:** AIO BrokerAuthorization resource restricting `511-teams-notification` to subscribe on `alerts/#` and publish on `notifications/#` only

### Key Vault Integration

| Secret | Component | Purpose |
|--------|-----------|---------|
| `teams-webhook-url` | 511-teams-notification | Teams Incoming Webhook URL |
| AIO MQTT CA cert | All edge services | Broker TLS trust chain |
| ACSA storage key | 503-media-capture | Cloud sync authentication |

### RBAC Requirements

| Identity | Role | Scope | Purpose |
|----------|------|-------|---------|
| AIO UAMI | Azure Event Hubs Data Sender | Event Hub namespace | Dataflow write |
| AIO UAMI | Storage Blob Data Contributor | Storage account | ACSA media sync |
| Secret Sync identity | Key Vault Secrets User | Key Vault | Runtime secret retrieval |
| Arc onboarding SP | Kubernetes Cluster Admin | Subscription | Arc onboarding |

---

## 7. Observability

### OpenTelemetry Tracing Spans

Every leak detection event should carry a distributed trace from detection to notification:

```text
Trace: leak-detection-{event_id}
├── span: sse-connector/receive-event          (509)
├── span: mqtt-broker/publish-raw              (AIO)
├── span: ai-inference/run-model               (507)
│   ├── span: inference/preprocess
│   ├── span: inference/execute
│   └── span: inference/postprocess
├── span: mqtt-broker/publish-alert            (AIO)
├── span: teams-notification/receive-alert     (511)
│   ├── span: teams/dedup-check
│   ├── span: teams/build-adaptive-card
│   └── span: teams/send-webhook
├── span: media-capture/trigger-capture        (503)
│   ├── span: media/extract-buffer
│   └── span: media/cloud-sync
└── span: dataflow/route-to-eventhub           (130)
```

The AIO SDK receiver automatically propagates trace context from MQTT message headers. The 501 pattern already demonstrates this with `handle_receive_trace()`.

### Grafana Dashboards

Ripley should deploy a Grafana dashboard (via 020-observability) with:

| Panel | Metric | Alert Threshold |
|-------|--------|-----------------|
| Leak Events / Hour | Count of `ALERT_DLQC` events | > 50/hr → warning |
| Detection Latency | P95 duration: SSE receive → alert publish | > 500ms → warning |
| Notification Latency | P95 duration: alert receive → Teams 200 OK | > 5s → critical |
| Teams Webhook Errors | Count of non-2xx responses in sliding window | > 5/hr → warning |
| Media Capture Success Rate | Captures completed / captures triggered | < 95% → warning |
| Inference Confidence Distribution | Histogram of `confidence_level` values | Informational |
| Active Cameras | Count of cameras with heartbeat in last 60s | < expected → critical |

### Log Analytics Queries

```kql
// Leak events in last 24 hours by severity
ContainerLog
| where LogEntry contains "ALERT_DLQC"
| extend confidence = toint(extract("confidence_level\":(\\d+)", 1, LogEntry))
| extend severity = case(
    confidence >= 80, "CRITICAL",
    confidence >= 60, "HIGH",
    confidence >= 40, "MEDIUM",
    "LOW"
  )
| summarize count() by severity, bin(TimeGenerated, 1h)
| render columnchart

// Teams notification latency
ContainerLog
| where ContainerName == "teams-notification"
| where LogEntry contains "webhook_duration_ms"
| extend latency_ms = todouble(extract("webhook_duration_ms=(\\d+)", 1, LogEntry))
| summarize percentile(latency_ms, 95) by bin(TimeGenerated, 5m)
```

### SLA/SLO Targets

| Metric | SLO | Measurement |
|--------|-----|-------------|
| Detection-to-notification latency | < 5 seconds (P95) | End-to-end trace duration |
| Notification delivery success rate | > 99.5% | Teams webhook 2xx / total attempts |
| Detection model uptime | > 99.9% | Inference engine health check |
| Event ingestion availability | > 99.9% | SSE connector health check |
| Media capture success rate | > 95% | Captures completed / triggered |

---

## 8. Implementation Plan

### 8.1 Phase 1 — Parker: 511-teams-notification

Parker implements the Teams notification Rust microservice. This is the only greenfield application code.

**Prerequisite:** This design document (Parker reads §3.2, §4, §5 for contracts)

| # | Task | File Path | Notes |
|---|------|-----------|-------|
| 1 | Create Cargo.toml | `src/500-application/511-teams-notification/services/teams-notification/Cargo.toml` | Use deps from §3.2.10 |
| 2 | Implement `main.rs` | `…/src/main.rs` | Follow 501 AIO SDK pattern (§3.2.3) |
| 3 | Implement `config.rs` | `…/src/config.rs` | Env var parsing per §3.2.9 |
| 4 | Implement `alert.rs` | `…/src/alert.rs` | ALERT_DLQC struct per §3.2.4, §4 |
| 5 | Implement `teams.rs` | `…/src/teams.rs` | Webhook client per §3.2.5 |
| 6 | Implement `adaptive_card.rs` | `…/src/adaptive_card.rs` | Adaptive Card builder per §3.2.5 |
| 7 | Implement `dedup.rs` | `…/src/dedup.rs` | Per §3.2.6 |
| 8 | Implement `health.rs` | `…/src/health.rs` | Axum health server per §3.2.8 |
| 9 | Implement `otel.rs` | `…/src/otel.rs` | Copy pattern from 501 receiver |
| 10 | Create Dockerfile | `…/Dockerfile` | Multi-stage Rust build |
| 11 | Create docker-compose.yaml | `src/500-application/511-teams-notification/docker-compose.yaml` | Local dev with MQTT broker |
| 12 | Create Helm chart | `src/500-application/511-teams-notification/charts/teams-notification/` | Deployment + Service |
| 13 | Write README.md | `src/500-application/511-teams-notification/README.md` | Follow repo README conventions |

### 8.2 Phase 2 — Ripley: Leak Detection Blueprint & IaC

Ripley creates the Terraform blueprint and asset definitions. Depends on Phase 1 being code-complete (for container image reference in Helm chart values).

**Prerequisite:** This design document (Ripley reads §3.3, §3.4, §5, §6)

| # | Task | File Path | Notes |
|---|------|-----------|-------|
| 1 | Create blueprint directory | `blueprints/leak-detection/terraform/` | Follow `full-single-node-cluster` pattern |
| 2 | Create `main.tf` | `blueprints/leak-detection/terraform/main.tf` | Module composition per §3.4 |
| 3 | Create `variables.tf` | `blueprints/leak-detection/terraform/variables.tf` | Match component variable names exactly |
| 4 | Create `variables.core.tf` | `blueprints/leak-detection/terraform/variables.core.tf` | Standard: environment, resource_prefix, location, instance |
| 5 | Create `variables.deps.tf` | `blueprints/leak-detection/terraform/variables.deps.tf` | Dependencies between modules |
| 6 | Create `outputs.tf` | `blueprints/leak-detection/terraform/outputs.tf` | Key outputs for downstream use |
| 7 | Create `versions.tf` | `blueprints/leak-detection/terraform/versions.tf` | Provider constraints |
| 8 | Create CI tfvars | `src/100-edge/111-assets/ci/terraform/leak-detection.auto.tfvars` | Minimal vars for asset testing |
| 9 | Create example tfvars | `blueprints/leak-detection/terraform/leak-detection.tfvars.example` | Complete example config |
| 10 | Create `README.md` | `blueprints/leak-detection/README.md` | Blueprint documentation |
| 11 | Grafana dashboard JSON | Via 020-observability configuration | Per §7 panel definitions |

### 8.3 Phase 3 — Lambert: Test Strategy

Lambert designs and implements tests. Depends on Phase 1 code completion.

**Prerequisite:** This design document (Lambert reads §4, §5, §12)

| # | Test Category | Scope | Approach |
|---|---------------|-------|----------|
| 1 | Unit: alert deserialization | `alert.rs` | Test ALERT_DLQC parsing, edge cases, malformed JSON |
| 2 | Unit: severity derivation | `alert.rs` | Boundary values: 0, 39, 40, 59, 60, 79, 80, 100 |
| 3 | Unit: Adaptive Card format | `adaptive_card.rs` | Validate JSON structure matches Teams schema |
| 4 | Unit: dedup cache | `dedup.rs` | Window expiry, duplicate detection, eviction |
| 5 | Unit: rate limiting | `dedup.rs` | Per-camera and global rate limits |
| 6 | Integration: MQTT → Teams | Full service | Mock MQTT broker + mock webhook endpoint |
| 7 | Integration: health endpoints | `health.rs` | HTTP GET /health and /readiness |
| 8 | Terraform: blueprint plan | `blueprints/leak-detection/terraform/` | `command = plan` only |
| 9 | Terraform: asset definitions | `src/100-edge/111-assets/` | Validate asset variables accepted |
| 10 | E2E: detection pipeline | Full stack | SSE → broker → inference → alert → notification (manual verification guide) |

---

## 9. Delegation Matrix

| Task | Agent | Inputs | Outputs | Dependencies |
|------|-------|--------|---------|--------------|
| 511-teams-notification service | Parker | §3.2, §4, §5 of this document; 501 receiver pattern | Rust service, Dockerfile, Helm chart, docker-compose, README | None |
| Leak detection blueprint | Ripley | §3.4, §6 of this document; full-single-node-cluster reference | `blueprints/leak-detection/terraform/` full module set | None (parallel with Parker) |
| Asset definitions (tfvars) | Ripley | §3.3 of this document; 111-assets variable schema | Example tfvars for leak detection assets | None (parallel) |
| Grafana dashboard config | Ripley | §7 of this document; 020-observability patterns | Dashboard JSON / Terraform config | Blueprint completion |
| Unit tests for 511 | Lambert | Parker's source code; §4 schema | Rust test modules | Phase 1 complete |
| Integration tests for 511 | Lambert | Parker's complete service | Docker Compose test harness | Phase 1 complete |
| Terraform plan tests | Lambert | Ripley's blueprint | `.tftest.hcl` files (`command = plan`) | Phase 2 complete |
| Code review of all work | Dallas | All outputs above | Approval or revision requests | Phases 1–3 complete |

---

## 10. Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Teams webhook URL expires or is rotated | Notifications stop | Medium | Store in Key Vault with rotation policy; monitor `notifications/*/teams/failed` topic |
| Leak detection model accuracy insufficient | False positives flood Teams channel | High | Confidence threshold filtering (only notify on ≥40%); per-camera rate limiting |
| SSE connector drops connection to camera | Event loss during reconnect | Medium | SSE client has built-in exponential backoff reconnection; heartbeat monitoring detects gaps |
| MQTT broker restart causes message loss | In-flight ALERT_DLQC events dropped | Low | QoS 1 (at-least-once) with session persistence; AIO broker is HA |
| Teams rate limiting (connector limit) | Notifications delayed during burst events | Medium | Global rate limit of 10/min; dedup cache; queue and batch during high-volume |
| Video evidence capture fails (RTSP timeout) | Missing forensic evidence | Medium | Ring buffer ensures pre-event capture exists; ACSA retry on cloud sync failure |
| Network partition (edge ↔ cloud) | Events queued, cloud dashboards stale | Low | AIO dataflow buffering; store-and-forward when reconnected; edge has local monitoring |
| Container image pull failure (ACR unreachable) | New service versions can't deploy | Low | ACR pull-through cache; pre-pull images on K3s node |
| Inference engine OOM on small edge hardware | 507 pod evicted | Medium | Set Kubernetes resource limits; use Candle backend (lower memory footprint) |

---

## 11. Non-Goals (Milestone 1)

The following are explicitly **out of scope** for this milestone:

1. **Cloud-side analytics pipelines** — Stream Analytics, Functions, or Data Factory processing of leak events in the cloud. The data arrives in Event Hub; downstream consumption is a separate workstream.
2. **Model training** — Training leak detection models via Azure ML (080-azureml). Milestone 1 assumes a pre-trained ONNX model is provided.
3. **Multi-node cluster support** — This design targets a single-node K3s cluster. Multi-node HA is a future blueprint.
4. **Fabric / Fabric RTI integration** — The dataflow module supports it, but it's not wired in the leak-detection blueprint.
5. **Custom Teams bot** — We use a simple Incoming Webhook. A full Teams Bot Framework integration is out of scope.
6. **Mobile notifications** — Push notifications to mobile devices (beyond Teams mobile app).
7. **Automated incident response** — Automated valve shutoff or process control actions. This is notification-only.
8. **PostgreSQL time-series storage** — The 035-postgresql component exists but is not included in Phase 1.
9. **VPN Gateway** — Optional in blueprint but not required for Milestone 1.
10. **OPC-UA integration** — This design uses SSE-based cameras. OPC-UA sensor integration (pressure, flow sensors) is a future milestone.

---

## 12. Verification Guide

Step-by-step guide to verify the full pipeline end-to-end.

### Prerequisites

- Leak detection blueprint deployed (`blueprints/leak-detection/terraform/`)
- Teams Incoming Webhook URL configured in Key Vault
- SSE server running (use the 509 simulator for testing)
- `kubectl` access to the edge cluster
- `mosquitto_sub` available (or use AIO MQTT client pod)

### Step 1: Verify SSE Connector is Receiving Events

```bash
# Check SSE connector pod status
kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=sse-connector

# View SSE connector logs (should show event counts)
kubectl logs -l app.kubernetes.io/name=sse-connector -n azure-iot-operations --tail=20
```

Expected: Pod running, logs showing `Events Received: N`, `HEARTBEAT`, `ALERT_DLQC` events.

### Step 2: Verify MQTT Topic Delivery

```bash
# Subscribe to all leak alert topics
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  mosquitto_sub --host aio-broker --port 18883 \
  --username 'K8S-SAT' --pw $(cat /var/run/secrets/tokens/broker-sat) \
  --cafile /var/run/certs/ca.crt \
  --topic 'alerts/#' -v
```

Expected: `ALERT_DLQC` JSON payloads appearing on `alerts/{facility}/{device}/leak/dlqc`.

### Step 3: Verify AI Inference Processing

```bash
# Check inference pod
kubectl get pods -n azure-iot-operations -l app=ai-edge-inference

# View inference logs
kubectl logs -l app=ai-edge-inference -n azure-iot-operations --tail=20
```

Expected: Inference results with confidence levels being published.

### Step 4: Verify Teams Notification Delivery

```bash
# Check teams-notification pod
kubectl get pods -n azure-iot-operations -l app=teams-notification

# View notification logs
kubectl logs -l app=teams-notification -n azure-iot-operations --tail=20
```

Expected: Logs showing `Alert received`, `Webhook sent successfully`, `event_id=NNNN`.

**Manual verification:** Check the configured Teams channel for Adaptive Cards with leak detection information.

### Step 5: Verify Media Capture

```bash
# Check media-capture pod
kubectl get pods -n azure-iot-operations -l app=media-capture-service

# Check captured files
kubectl exec -it media-capture-pod -n azure-iot-operations -- ls -la /capture/
```

Expected: `.mp4` files with timestamps matching recent `ALERT_DLQC` events.

### Step 6: Verify Edge-to-Cloud Dataflow

```bash
# Check dataflow status
kubectl get dataflows -n azure-iot-operations

# Verify events in Event Hub (Azure Portal or CLI)
az eventhubs eventhub show --resource-group <rg> --namespace-name <ns> --name <eh> \
  --query "messageCountDetails"
```

Expected: Incoming message count increasing in Event Hub.

### Step 7: End-to-End Latency Check

```bash
# Subscribe to notification confirmation topic
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  mosquitto_sub --host aio-broker --port 18883 \
  --username 'K8S-SAT' --pw $(cat /var/run/secrets/tokens/broker-sat) \
  --cafile /var/run/certs/ca.crt \
  --topic 'notifications/#' -v
```

Compare timestamps: `ALERT_DLQC.timestamp` vs. `notification sent` timestamp. Target: < 5 seconds.

---

*Prepared by Dallas (Lead Architect) for the Edge AI Leak Detection Accelerator.*
*All code samples are illustrative for design purposes. Parker owns final implementation.*
