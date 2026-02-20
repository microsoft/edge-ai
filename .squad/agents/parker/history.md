# History — Parker

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo
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

### 2026-02-18: Deep technical analysis of 509-sse-connector and 503-media-capture-service deployment requirements

**Requested by:** Carlos Sardo (feeds into leak-detection implementation plan)

---

#### 509-SSE-CONNECTOR ANALYSIS

**Component location:** `src/500-application/509-sse-connector/`

**Technology:** Python 3.12 on Azure Linux 3.0 (SHA-pinned). Single dependency: `aiohttp>=3.12.14`.

**Architecture:**
- `sse-server/` — SSE HTTP server that streams analytics camera events (HEARTBEAT, ALERT, ALERT_DLQC, ANALYTICS_ENABLED, ANALYTICS_DISABLED)
- `connector-test-client/` — Test client that bridges SSE events to MQTT topics (simulates Akri SSE connector behavior). Dependencies: `aiohttp>=3.12.14`, `paho-mqtt==2.0.0`.
- Docker Compose local dev stack: Mosquitto broker, SSE server, connector test client, MQTT monitor.

**Dockerfile** (`services/sse-server/Dockerfile`):
- Base: `mcr.microsoft.com/azurelinux/base/python:3.12` (SHA-pinned)
- Build context: `./services/sse-server` (docker-compose sets this)
- Installs `ca-certificates`, `shadow-utils`, creates non-root `appuser`
- `pip install --no-cache-dir -r requirements.txt`
- Copies `sse_server.py` and `events_simulator.py`
- Exposes port 8080
- HEALTHCHECK: `python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')"`
- CMD: `python3 sse_server.py`

**SSE Server env vars at runtime:**

| Variable | Default | Required |
|---|---|---|
| `DEVICE_ID` | `analytics-camera-001` | No |
| `PORT` | `8080` | No |
| `HEARTBEAT_INTERVAL` | `5` | No |
| `ALERT_PROBABILITY` | `0.1` | No |

**SSE endpoints:**
- `GET /camera-events` — SSE stream (Content-Type: text/event-stream)
- `GET /health` — JSON health check
- `GET /` — Server info and capability discovery

**Exact `az acr build` command:**
```bash
az acr build --registry <ACR_NAME> --image sse-connector/sse-server:<TAG> ./src/500-application/509-sse-connector/services/sse-server
```
Build context: `src/500-application/509-sse-connector/services/sse-server/` (Dockerfile is self-contained, only COPYs files from its own directory: `requirements.txt`, `sse_server.py`, `events_simulator.py`)

**Kubernetes manifests: NONE EXIST.**

There are NO Kubernetes manifests, Helm charts, or Kustomize overlays anywhere in 509-sse-connector. The component only has Docker Compose for local dev, and the README states production deployment uses the Akri connector framework via Terraform (110-iot-ops akri-connectors module for the connector itself).

However, the SSE *server* pod (the event source that the Akri connector connects to) needs to run in-cluster. For the leak-detection blueprint where the SSE server must be reachable at `analytics-camera:8080` in namespace `azure-iot-operations`, the minimal K8s manifests needed are:

1. **Deployment** — 1 replica, container from ACR image, port 8080, env vars (DEVICE_ID, PORT, HEARTBEAT_INTERVAL, ALERT_PROBABILITY), liveness/readiness probes on `/health`
2. **Service** — ClusterIP service named `analytics-camera`, port 8080 → targetPort 8080
3. **No volumes needed** — stateless Python server
4. **No SAT/TLS volumes** — SSE server doesn't connect to AIO broker (it's a source, not a consumer)
5. **No PVC** — no persistent storage

**Gap confirmed:** The SSE server has no way to deploy to Kubernetes today. Manifests (Helm chart or bare YAML) must be created for the leak-detection blueprint.

---

#### 503-MEDIA-CAPTURE-SERVICE ANALYSIS

**Component location:** `src/500-application/503-media-capture-service/`

**Technology:** Rust binary (`multi_trigger`) on Azure Linux 3.0 (SHA-pinned). Heavy build: compiles x264, FFmpeg 7.1.1, OpenCV 4.10.0 from source in multi-stage Dockerfile. Runtime binary name: `multi_trigger`. Entry point: `/run.sh` which executes `./multi_trigger`.

**Dockerfile** (`services/media-capture-service/Dockerfile`):
- **Build stage:** Azure Linux 3.0 core, installs full C/C++ toolchain + Rust (stable via rustup), builds x264 → FFmpeg → OpenCV from source. Then builds Rust binary with dependency-caching layer.
- **COPY paths are relative to component root** (not services dir):
  ```
  COPY ./services/media-capture-service/Cargo.toml ./Cargo.toml
  COPY ./services/media-capture-service/Cargo.lock ./Cargo.lock
  COPY ./services/media-capture-service/.cargo ./.cargo
  COPY ./services/media-capture-service/src ./src
  COPY ./services/media-capture-service/run.sh /
  ```
- **Runtime stage:** Azure Linux 3.0 core, copies binary + FFmpeg/OpenCV shared libs.
- **No EXPOSE** — no HTTP port (communicates via MQTT only)
- CMD: `/run.sh`

**Exact `az acr build` command:**
```bash
az acr build --registry <ACR_NAME> --image media-capture-service:<TAG> ./src/500-application/503-media-capture-service
```
Build context: `src/500-application/503-media-capture-service/` (the entire component root, because Dockerfile COPYs `./services/media-capture-service/*` paths relative to this root).

**NOTE:** The deploy script uses `docker build -f "${COMPONENT_DIR}/Dockerfile" -t "${image_tag}" .` from `COMPONENT_ROOT` (the component directory), confirming context = component root.

**Helm Chart** (`charts/media-capture-service/`):
- Chart.yaml: `media-capture-service` v0.1.0, apiVersion v2, type application
- Templates: `_helpers.tpl`, `deployment.yaml`, `service.yaml`
- Deployment creates: container with all env vars injected, SAT volume (projected serviceAccountToken, audience `aio-internal`, 86400s expiry), trust-bundle volume (ConfigMap `azure-iot-operations-aio-ca-trust-bundle`), media-storage PVC volume (`pvc-acsa-cloud-backed`)
- Service: ClusterIP, port 8080
- imagePullSecrets: `acr-auth`
- Pod runs as user 1000, non-root, drops all capabilities

**Full env vars / secrets required by 503 at runtime:**

| Variable | Source | Default | Required |
|---|---|---|---|
| `AIO_BROKER_HOSTNAME` | Helm values / env | `aio-broker.azure-iot-operations` | Yes |
| `AIO_BROKER_TCP_PORT` | Helm values / env | `18883` | Yes |
| `AIO_TLS_CA_FILE` | Helm values / env | `/var/run/certs/ca.crt` | Yes (TLS mode) |
| `AIO_SAT_FILE` | Helm values / env | `/var/run/secrets/tokens/mq-sat` | Yes (TLS mode) |
| `AIO_MQTT_CLIENT_ID` | Helm values / env | `media-capture-service` | No |
| `AIO_MQTT_USE_TLS` | env only | `true` | No (defaults true) |
| `TRIGGER_TOPICS` | Helm values / env | `["topic/path/to/trigger"]` | Yes |
| `MEDIA_CLOUD_SYNC_DIR` | Helm values / env | `/cloud-sync/media` | Yes |
| `RTSP_URL` | Helm values / env | (none — panics if unset) | **Yes (REQUIRED)** |
| `VIDEO_FPS` | Helm values / env | `20` (code default) | No |
| `FRAME_WIDTH` | Helm values / env | `896` | No |
| `FRAME_HEIGHT` | Helm values / env | `512` | No |
| `BUFFER_SECONDS` | Helm values / env | `60` | No |
| `CAPTURE_DURATION_SECONDS` | Helm values / env | `10` | No |
| `VIDEO_FEED_DELAY_SECONDS` | Helm values / env | `5` | No |
| `RUST_LOG` | Helm values / env | `info` | No |
| `VIDEO_FORMAT` | env only (not in Helm) | (code default) | No |
| `FILENAME_FORMAT` | env only (not in Helm) | (code default) | No |
| `BUFFER_CLEANUP_INTERVAL_SECS` | env only (not in Helm) | (code default) | No |
| `MAX_OLD_FRAMES_AGE_SECS` | env only (not in Helm) | (code default) | No |

**Critical:** `RTSP_URL` and `MEDIA_CLOUD_SYNC_DIR` are `expect()`-panics in Rust code — the service will crash if they are unset.

**Azure infrastructure prerequisites (from deploy script):**

| Requirement | Details |
|---|---|
| ACR | Azure Container Registry for image storage |
| Storage Account | For Azure Container Storage Enabled by Arc (ACSA) cloud-backed storage |
| ACSA Extension | `microsoft.arc.containerstorage` on the Arc-connected cluster |
| Arc-connected K8s cluster | With `az connectedk8s proxy` connectivity |
| Storage roles | `Storage Blob Data Contributor` (current user), `Storage Blob Data Owner` (ACSA extension identity) |
| Storage container | `media` container in the storage account |

**YAML prerequisites:**
- `yaml/cloudBackedPVC.yaml` — PersistentVolumeClaim: `pvc-acsa-cloud-backed`, namespace `azure-iot-operations`, 3Gi, storageClass `cloud-backed-sc`, access mode ReadWriteMany
- `yaml/mediaEdgeSubvolume.yaml` — EdgeSubvolume CR: `media`, uses `envsubst` for `${STORAGE_ACCOUNT_ENDPOINT}`, auth type MANAGED_IDENTITY, container `media`

**EXACT deployment steps for 503 (from deploy script `main()`):**

1. **Prerequisites check** — verify ACR_NAME, STORAGE_ACCOUNT_NAME, ST_ACCOUNT_RESOURCE_GROUP, CLUSTER_NAME, CLUSTER_RESOURCE_GROUP env vars; verify docker, az, kubectl, helm commands
2. **Build and push image** — `docker build -f services/media-capture-service/Dockerfile -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION} .` from component root, then `az acr login --name ${ACR_NAME}` and `docker push`
3. **Connect to cluster** — `az connectedk8s proxy -n ${CLUSTER_NAME} -g ${CLUSTER_RESOURCE_GROUP}`
4. **Configure ACSA** — `kubectl apply -f yaml/cloudBackedPVC.yaml`
5. **Assign storage roles** — get subscription ID, assign `Storage Blob Data Contributor` to signed-in user, get ACSA extension identity via `az k8s-extension list`, assign `Storage Blob Data Owner` to ACSA identity
6. **Create storage container** — `az storage container create --account-name ${STORAGE_ACCOUNT_NAME} --name media --auth-mode login`
7. **Apply subvolume config** — `envsubst < yaml/mediaEdgeSubvolume.yaml | kubectl apply -f -` (requires `STORAGE_ACCOUNT_ENDPOINT=https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/`)
8. **Generate env config** — runs `scripts/generate-env-config.sh` to create `.env` file
9. **Deploy Helm chart** — `helm upgrade --install media-capture-service charts/media-capture-service/ --namespace azure-iot-operations --set image.repository=... --set image.tag=... [all other --set flags from env vars] --wait --timeout=300s`
10. **Verify deployment** — poll for Running pods with label `app.kubernetes.io/name=media-capture-service` (up to 10 retries × 15s)

**Deployment automation gaps for Terraform:**
- The deploy script is entirely shell-based (not Terraform)
- Steps 4-7 (ACSA PVC, storage roles, storage container, subvolume) are Azure infra that should be in Terraform
- Step 9 (Helm deploy) can use `helm_release` in Terraform
- Step 2 (build/push) can use `terraform_data` + `local-exec` or `az acr build`
- The Helm chart is ready and functional — no changes needed to templates

**Docker Compose** (local dev):
- Build context: `.` (component root), Dockerfile: `services/media-capture-service/Dockerfile`
- Platform: `linux/amd64` forced
- Loads `.env` file for all config
- Overrides for local: `AIO_BROKER_HOSTNAME=mosquitto-broker`, `AIO_BROKER_TCP_PORT=1883`, `AIO_MQTT_USE_TLS=false`
- Mounts `./resources/media:/cloud-sync/media` for local media storage
- Local Mosquitto broker included

---

#### Cross-component observations

1. **509 has no K8s deployment mechanism** — must create Helm chart or Kustomize manifests before it can run in the cluster
2. **503 has a complete Helm chart** — ready for `helm_release` in Terraform
3. **503 Dockerfile build context is the component root** — critical for `az acr build` path
4. **509 Dockerfile build context is the service subdir** — simpler, self-contained
5. **Both target Azure Linux 3.0** — consistent base images
6. **503 depends on ACSA (Azure Container Storage enabled by Arc)** — requires PVC + EdgeSubvolume CR + storage roles
7. **509 is stateless** — no volumes, no MQTT connection, just serves HTTP SSE
8. **503 uses AIO MQTT SDK** (`azure_iot_operations_mqtt`) — needs SAT token + CA trust bundle volumes
9. **For the leak-detection blueprint**, the TRIGGER_TOPICS for 503 must be set to the topics that carry leak alert events (from the 507/509 pipeline)

📌 Team update (2025-07-25): 507 Dockerfile cross-compilation scaffolding (`FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx`, `COPY --from=xx / /`, `ARG TARGETPLATFORM`) removed for ACR Build compatibility. ACR Build's dependency scanner cannot parse `--platform=$BUILDPLATFORM` in FROM lines (static analysis, not runtime eval). No functional impact — cross-compilation not needed for ACR Build on amd64. File: `src/500-application/507-ai-inference/services/ai-edge-inference/Dockerfile` (modified, uncommitted). 503-media-capture-service Dockerfile cross-checked and already compatible — noted by Scribe (Carlos directive)

### 2026-02-19: Switched from ACR Build to local Docker builds + push

**Requested by:** Carlos Sardo

**Files created:**
- `blueprints/leak-detection/scripts/build-app-images-local.sh` — local Docker build for all 3 edge app images (509, 507, 503)

**Files modified:**
- `blueprints/leak-detection/scripts/build-app-images.sh` — converted from `az acr build` to `docker tag` + `docker push` for pre-built local images

**Why:** ACR Build's constrained server-side environment causes layer eviction on large images (503-media-capture-service compiles FFmpeg, OpenCV, and Rust — ~30 min build exceeding ACR Build resource limits).

**Key patterns established:**
- Two-stage workflow: `build-app-images-local.sh` (build) → `build-app-images.sh` (push). Build is self-contained; push is Terraform-invoked.
- Local build script derives all paths from its own location — no Terraform env vars required for building. `TF_IMAGE_VERSION` defaults to `latest`.
- Push script validates local image existence via `docker image inspect` before attempting push, with clear error message pointing to the local build script.
- Image names unchanged: `sse-server`, `ai-edge-inference`, `media-capture-service` — maintains compatibility with downstream Kubernetes manifests and Helm charts.
- `TF_APP_*_PATH` env vars no longer validated by push script (Terraform still sets them but they're unused).

**Decision:** `.ai-team/decisions/inbox/parker-local-docker-builds.md`
