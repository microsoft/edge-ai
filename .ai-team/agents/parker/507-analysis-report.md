# 507 AI Inference — Technical Analysis Report

**Author:** Parker (Edge Developer)
**Date:** 2025-07-25
**Scope:** Deep analysis of 507-ai-inference and cross-comparison with all application deployment patterns

---

## 1. Application Directory Catalog

All 11 directories under `src/500-application/`:

| # | Directory | Language | Dockerfile | Deployment Method | Deploy Script | Base Image | Status |
|---|-----------|----------|-----------|-------------------|---------------|------------|--------|
| 500 | basic-inference | Python | Yes | Helm (charts/) | No | Unknown | Active |
| 501 | rust-telemetry | Rust 1.86 | Yes (×2: receiver, sender) | None (raw manifests) | No | Azure Linux 3.0 | Active |
| 502 | rust-http-connector | Rust | Yes | None | No | Unknown | Active |
| 503 | media-capture-service | Rust 1.86 | Yes | Helm (charts/) | Yes (562 lines) | Azure Linux 3.0 | Active |
| 504 | mqtt-otel-trace-exporter | Go | Yes | Helm (charts/) | No | Unknown | Active |
| 505 | akri-rest-http-connector | Rust | Yes | None | No | Unknown | Active |
| 506 | ros2-connector | Rust | Yes | Helm (charts/) | No | Unknown | Active |
| 507 | ai-inference | Rust 1.88 | Yes | Kustomize (charts/) | Yes (334 lines) | CBL-Mariner 2.0 | Active |
| 508 | media-connector | N/A | No (.nobuild) | N/A (uses MCR images) | No | N/A | Dev-only |
| 509 | sse-connector | Rust | Yes (×2: connector-test-client, sse-server) | None | No | Unknown | Active |
| 510 | onvif-connector | Unknown | Unknown | Unknown | No | Unknown | Active |

### Deployment Method Breakdown

- **Helm charts:** 500, 503, 504, 506
- **Kustomize:** 507 (only one)
- **No deployment tooling:** 501, 502, 505, 509, 510
- **Not buildable:** 508 (`.nobuild` — uses pre-built MCR images)

---

## 2. 507-ai-inference — Full Inventory

### Directory Structure

```text
507-ai-inference/
├── README.md                              (307 lines)
├── docker-compose.yaml                    (62 lines)
├── services/
│   ├── ai-edge-inference/                 (main binary)
│   │   ├── Cargo.toml                     (100 lines)
│   │   ├── Dockerfile                     (167 lines)
│   │   ├── .cargo/                        (registry config)
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── config.rs
│   │   │   ├── health.rs
│   │   │   ├── health_simple.rs
│   │   │   ├── inference.rs
│   │   │   ├── message_handler.rs
│   │   │   ├── metrics.rs
│   │   │   ├── models.rs
│   │   │   ├── mqtt.rs
│   │   │   └── topic_router.rs
│   │   ├── scripts/
│   │   │   └── deploy.sh                  (334 lines)
│   │   └── tests/
│   │       ├── test-mobilenet-dual-backend.sh
│   │       ├── test-mqtt-inference.sh
│   │       ├── test-yolov2-dual-backend.sh
│   │       └── test-real-inference.py
│   └── ai-edge-inference-crate/           (shared library)
│       ├── Cargo.toml                     (99 lines)
│       └── src/
├── charts/
│   ├── kustomization.yaml                 (overlay)
│   ├── gen-patch.sh                       (60 lines)
│   ├── patch-containers.yaml
│   ├── model-downloader-job.yaml
│   └── base/
│       ├── kustomization.yaml
│       ├── deployment.yaml                (186 lines)
│       ├── service.yaml
│       ├── serviceaccount.yaml
│       └── pvc-models.yaml
└── resources/
    ├── model_configs/
    │   ├── industrial-safety.yaml         (includes "leak" class label)
    │   ├── mobilenetv2.yaml
    │   ├── yolov8n.yaml
    │   └── (enhanced variants)
    ├── models/
    │   ├── default.onnx                   (placeholder)
    │   ├── mobilenet.onnx                 (placeholder)
    │   └── tinyyolov2-8.onnx             (placeholder)
    └── mosquitto.conf
```

### Crate Dependencies

**ai-edge-inference (binary):**

- AIO SDK: `azure_iot_operations_mqtt` 0.9.0, `azure_iot_operations_protocol` 0.9.0, `azure_iot_operations_services` 0.8.0 (from Azure Artifacts `aio-sdks` registry)
- MQTT: `rumqttc`
- HTTP: `warp` (health), `axum` (metrics)
- Observability: `prometheus`, `tracing`, `tracing-subscriber`
- Runtime: `tokio` (full features)
- Serialization: `serde`, `serde_json`, `serde_yaml`

**ai-edge-inference-crate (library):**

- ML backends: `ort` 2.0.0-rc.10 (ONNX, behind `onnx` feature), `candle-core`/`candle-nn`/`candle-transformers` 0.9 (behind `candle` feature)
- Image processing: `image`
- Audio: `hound`, `dasp` (behind features)
- Configuration: `config`
- Feature flags: `onnx`, `candle`, `gpu`, `cpu-only`, `pure-rust`

---

## 3. Docker Build Chain

### Build Flow

```text
docker-compose.yaml
  context: ./services        ← both crates in scope
  dockerfile: ai-edge-inference/Dockerfile
  args: BACKEND=${AI_BACKEND:-onnx}
```

### Dockerfile Stages

**Stage 1 — xx (cross-compilation):**
`tonistiigi/xx:master` — provides cross-platform build helpers.

**Stage 2 — build:**

1. Base: `mcr.microsoft.com/cbl-mariner/base/core:2.0` (SHA-pinned)
2. Installs: openssl-devel, gcc, clang, make, protobuf-devel, wget, tar (all version-pinned to Mariner 2.0)
3. Installs Rust 1.88.0 via rustup
4. Creates minimal `/installroot` with essential shared libraries
5. Conditionally downloads ONNX Runtime 1.17.0 (only if `BACKEND=onnx`)
6. Configures `.cargo/config.toml` with `aio-sdks` registry (Azure Artifacts feed)
7. Copies both crates (`ai-edge-inference-crate` as sibling, `ai-edge-inference` as working dir)
8. Builds with backend-specific features: `--features onnx-runtime` or `--features candle`
9. Writes `build-info.txt` with backend type and timestamp

**Stage 3 — runtime:**

1. Base: Same `cbl-mariner/base/core:2.0` (SHA-pinned, same as builder)
2. Installs minimal runtime deps: ca-certificates, shadow-utils, wget, tar
3. Creates non-root `appuser`
4. Copies ONNX Runtime from build stage
5. Copies binary as `/usr/local/bin/ai-edge-mqtt-publisher`
6. Sets environment: `RUST_LOG=info`, `MODEL_DIRECTORY=/models`, `METRICS_PORT=8080`, `HEALTH_PORT=8081`, `LD_LIBRARY_PATH=/opt/onnxruntime/lib`
7. `HEALTHCHECK` via `--health-check` flag
8. `ENTRYPOINT ["/usr/local/bin/ai-edge-mqtt-publisher"]`
9. Labels: `ai.edge.inference.backend`, version 0.2.0

### Build Issues

| Issue | Severity | Detail |
|-------|----------|--------|
| CBL-Mariner 2.0 vs Azure Linux 3.0 | Medium | 501 and 503 use Azure Linux 3.0; 507 is on the older Mariner 2.0 |
| Pinned package versions | High | `openssl-devel-1.1.1k-36.cm2`, `gcc-11.2.0-8.cm2` etc. — these will fail when Mariner 2.0 repo removes them |
| ONNX Runtime 1.17.0 | Low | Current latest is 1.22+; 1.17.0 is functional but dated |
| No dep caching layer | Low | 501 uses a dummy `Cargo.toml` layer for dependency caching; 507 does not |
| Cross-compilation stage unused | Informational | `xx` stage is copied but `$TARGETPLATFORM` is only used for conditional setup, actual build is native |

---

## 4. Deployment Pattern — Source to Running Container

### Manual Deployment Path

```text
Developer machine
  └─► deploy.sh (334 lines)
       ├─ check_prerequisites (docker, az, kubectl, kustomize)
       ├─ build_image
       │   └─ docker build from ../services context
       ├─ authenticate_acr (az acr login)
       ├─ push_image (docker push to ACR)
       │   └─ auto-tags latest for semver releases
       ├─ generate_patches
       │   └─ charts/gen-patch.sh → patch-containers.yaml
       ├─ apply_manifests
       │   └─ kubectl apply -k deployment/
       ├─ restart_pods (kubectl delete pod -l app=...)
       ├─ wait_for_rollout (300s timeout)
       └─ verify_deployment (pod count + status)
```

Flags: `--build-only`, `--deploy-only`, `--skip-restart`

### CI/CD Pipeline Path

```text
Git push to dev/internal-eng/pre-release
  └─► azure-pipelines.yml
       ├─ Changed folder detection (matrix)
       ├─ application-build-template.yaml
       │   └─ Application-Builder.ps1
       │       ├─ Docker Compose detection → docker compose build
       │       ├─ ACR push (if PushImages=true)
       │       ├─ Grype vulnerability scan
       │       └─ SLSA provenance generation
       └─ No post-build deployment step
```

507 has `docker-compose.yaml` so the CI pipeline will detect it and build via `docker compose build`. However, the pipeline only builds and pushes — there is no automated deployment to the edge cluster.

### Kubernetes Manifests (Kustomize)

**Base resources** (`charts/base/`):

- `deployment.yaml` — single replica, init container for models dir, main container from ACR
- `service.yaml` — ClusterIP with ports 8080 (metrics) and 8081 (health)
- `serviceaccount.yaml` — `ai-edge-inference-sa` with automountServiceAccountToken
- `pvc-models.yaml` — 10Gi PVC on `local-path` StorageClass

**Overlay** (`charts/kustomization.yaml`):

- Sets namespace: `azure-iot-operations`
- Applies JSON patches from `patch-containers.yaml` to replace container image

**Supplementary:**

- `model-downloader-job.yaml` — Kubernetes Job downloading TinyYOLOv2 and YOLOv4 from GitHub ONNX Models repo
- `gen-patch.sh` — generates `patch-containers.yaml` from env vars

### Kustomize vs Helm (Pattern Divergence)

507 is the **only** application using Kustomize. All other applications with deployment tooling (500, 503, 504, 506) use Helm charts. This creates an inconsistency in:

- Deployment tooling expectations
- Blueprint integration patterns
- CI/CD template assumptions

---

## 5. Runtime Secrets and Configuration

### Volumes

| Volume | Type | Mount | Purpose |
|--------|------|-------|---------|
| `mq-sat` | Projected ServiceAccountToken | `/var/run/secrets/tokens` (ro) | AIO MQTT broker auth (audience: `aio-internal`, expires: 3600s) |
| `trust-bundle` | ConfigMap | `/var/run/certs` (ro) | AIO CA trust bundle (`azure-iot-operations-aio-ca-trust-bundle`) |
| `models-volume` | PVC (10Gi, local-path) | `/models` | ML model storage |
| `logs-volume` | emptyDir | `/logs` | Runtime logs |

### Environment Variables (~30)

**AIO Broker Connection:**

- `AIO_BROKER_HOSTNAME=aio-broker.azure-iot-operations`
- `AIO_BROKER_TCP_PORT=18883`
- `AIO_TLS_CA_FILE=/var/run/certs/ca.crt`
- `AIO_SAT_FILE=/var/run/secrets/tokens/mq-sat`
- `AIO_MQTT_CLIENT_ID=ai-edge-inference-edge-device-01`

**Topic Configuration:**

- `MQTT_INPUT_TOPICS=edge-ai/+/+/camera/snapshots`
- `TOPIC_PREFIX=edge-ai/business_unit/facility/gateway_id/`
- `MQTT_QOS_LEVEL=1`

**Inference Configuration:**

- `INFERENCE_BACKEND=onnx`
- `ONNX_PROVIDERS=cpu`
- `DEFAULT_MODELS=tiny-yolov2`
- `MODEL_DIRECTORY=/models`
- `SKIP_MODEL_VALIDATION=true`

**GPU/Backend Flags:**

- `ENABLE_GPU=false`, `ENABLE_CUDA=false`, `ENABLE_TENSORRT=false`
- `FORCE_CPU_BACKEND=true`, `DISABLE_GPU_BACKENDS=true`
- `INFERENCE_MODE=cpu_only`, `FALLBACK_MODE=true`
- `ORT_DISABLE_ALL_OPTIMIZATIONS=1`, `ORT_FORCE_CPU_PROVIDER=1`

**Operational:**

- `DEVICE_NAME=edge-device-01`, `SITE=pilot-site`, `FACILITY=test-facility`
- `REGION=us-south`, `BUSINESS_UNIT=upstream`
- `METRICS_PORT=8080`, `HEALTH_PORT=8081`
- `DEMO_MODE=false`, `BYPASS_AI_ENGINE=false`, `MOCK_INFERENCE_RESULTS=false`
- `DEBUG_BACKEND_SELECTION=true`

### Dependencies on AIO Cluster Resources

The deployment assumes these AIO-provisioned resources exist:

1. `azure-iot-operations-aio-ca-trust-bundle` ConfigMap — created by AIO installation
2. `aio-internal` token audience — provisioned by AIO broker
3. `aio-broker.azure-iot-operations` DNS entry — created by AIO broker service
4. `local-path` StorageClass — typically available on K3s clusters

---

## 6. Automation Scripts

| Script | Location | Lines | Purpose |
|--------|----------|-------|---------|
| `deploy.sh` | `services/ai-edge-inference/scripts/` | 334 | Full build → push → deploy pipeline |
| `gen-patch.sh` | `charts/` | 60 | Generates Kustomize JSON patches |
| `Application-Builder.ps1` | `scripts/build/` | 417 | CI/CD PowerShell orchestrator (shared) |
| `application-build-template.yaml` | `.azdo/templates/` | 432 | Azure DevOps pipeline template (shared) |

### deploy.sh Detail

- Validates prerequisites: docker, az, kubectl, kustomize
- Builds from `../services` context (parent dir) so both crates are in scope
- Authenticates with ACR via `az acr login`
- Pushes image, auto-tags `latest` for semver releases
- Generates Kustomize patches via `gen-patch.sh`
- Applies via `kubectl apply -k deployment/`
- Monitors rollout with 300-second timeout
- Reports final pod status and service endpoints

### gen-patch.sh Detail

- Reads `ACR_NAME`, `IMAGE_NAME`, `IMAGE_VERSION`, `NAMESPACE` from environment
- Defaults: `ACR_NAME=acrmodules01`, `IMAGE_NAME=ai-edge-inference`, `NAMESPACE=azure-iot-operations`
- Generates JSON Patch (RFC 6902) replacing container image and namespace

---

## 7. What Exists, What's the Pattern, What's Missing

### What Exists

507 is a **fully implemented** dual-backend AI inference service with:

- Complete Rust codebase (10 source files, 2 crates)
- Multi-stage Dockerfile with configurable ONNX/Candle backends
- Kustomize-based Kubernetes manifests with init containers, SAT auth, PVC storage
- Manual deployment script (deploy.sh) covering the full lifecycle
- Model configuration for industrial safety (including leak detection classes)
- Docker Compose for local development
- Integration tests (4 scripts)
- Model downloader Job for bootstrapping ONNX models

### The Pattern

Across `src/500-application/`, the deployment pattern is:

1. **Build:** Docker multi-stage on Azure Linux (SHA-pinned), Rust toolchain, AIO SDK registry
2. **Registry:** Push to Azure Container Registry
3. **Deploy:** Helm (majority) or Kustomize (507 only) to `azure-iot-operations` namespace
4. **Auth:** ServiceAccount token (SAT) projected volumes + AIO CA trust bundle ConfigMap
5. **CI/CD:** Azure DevOps pipeline detects changes, builds via `Application-Builder.ps1`, pushes to ACR — but does NOT auto-deploy to edge

### What's Missing for Full Automation

| Gap | Impact | Recommended Owner |
|-----|--------|-------------------|
| **Not in leak-detection blueprint** | 507 has no Terraform module; blueprint creates ACR but nothing deploys the inference container | Ripley |
| **Health probes disabled** | `deployment.yaml` has liveness/readiness/startup probes commented out ("temporarily disabled for debugging") | Parker |
| **Base image drift** | CBL-Mariner 2.0 while 501/503 use Azure Linux 3.0 — security patching divergence | Parker |
| **Version-pinned OS packages** | Dockerfile pins exact versions (`openssl-devel-1.1.1k-36.cm2`) that will break on repo updates | Parker |
| **No Helm chart** | Only app using Kustomize; inconsistent with 500/503/504/506 Helm pattern | Parker (migration) or Ripley (integration) |
| **Hardcoded ACR in deployment.yaml** | `acrmodules01.azurecr.io` is hardcoded; should come from Kustomize overlay or Helm values | Parker |
| **No automated edge deployment** | CI/CD builds and pushes but does not deploy — manual `deploy.sh` required | Ripley (GitOps or pipeline extension) |
| **Model provisioning not automated** | `model-downloader-job.yaml` exists but is not applied by any automation — models must be manually deployed | Parker + Ripley |
| **No `.env` file** | Convention requires `.env` per README.md conventions; 507 only has `docker-compose.yaml` env vars inline | Parker |
| **Placeholder models** | `resources/models/` contains placeholder `.onnx` files, not production models | External (model pipeline) |

### Integration Path for leak-detection Blueprint

To fully automate 507 deployment within the leak-detection blueprint:

1. **Ripley:** Add a Kubernetes deployment module or Helm chart reference to the blueprint `main.tf` — either via `kubernetes_manifest` resources or a post-deploy step
2. **Parker:** Re-enable health probes in `deployment.yaml`
3. **Parker:** Migrate Dockerfile from CBL-Mariner 2.0 to Azure Linux 3.0 with dynamic package versions
4. **Parker:** Parameterize all hardcoded values (ACR name, image tag, model config path)
5. **Ripley:** Wire the ACR endpoint from `module.cloud_acr` into a mechanism that pushes the 507 image and deploys the Kustomize overlay (or convert to Helm for consistency)
6. **Ripley:** Add model download Job to the deployment pipeline or create a Terraform provisioner

---

## Appendix: Cross-Reference Matrix

### Which applications connect to AIO broker via SAT?

| App | SAT Volume | Trust Bundle | AIO SDK |
|-----|-----------|-------------|---------|
| 501 | Yes | Yes | Yes (0.9.0) |
| 507 | Yes | Yes | Yes (0.9.0) |
| 509 | Unknown (no manifests) | Unknown | Unknown |
| 511 | Superseded by Logic App | N/A | N/A |

### Model Configs Relevant to Leak Detection

`resources/model_configs/industrial-safety.yaml`:

- Declares `class_labels` including `"leak"` — confirms 507 was designed with leak detection in mind
- Uses placeholder model path — real model must replace `default.onnx`
