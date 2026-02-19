### 2026-02-19: E2E Edge Application Deployment — Consolidated Findings

**By:** Dallas (Lead), consolidating team work
**Status:** ACCEPTED
**What:** Consolidated record of all fixes and findings from the E2E deployment of leak detection edge applications (503-media-capture-service, 507-ai-inference, 509-sse-connector) to an Arc-connected K3s cluster running Azure IoT Operations.
**Why:** Captures institutional knowledge for future deployments and blueprint improvements. Nine distinct issues were encountered and resolved across infrastructure scripts, Kubernetes manifests, ACR configuration, and application containers.

---

## Deployment Script & Init Issues

### Fix 1 — init-scripts.sh unbound variable crash

- **File:** `src/100-edge/110-iot-ops/scripts/init-scripts.sh`
- **Symptom:** Script aborted under `set -euo pipefail` when environment variables were unset.
- **Root cause:** Variables referenced without default values; `nounset` flag treated them as errors.
- **Fix:** Added `${VAR:-}` default empty strings for all optional environment variables. Exported `KUBECONFIG`.

### Fix 2 — Missing kustomization.yaml for 509-sse-connector

- **File:** `src/500-application/509-sse-connector/charts/base/kustomization.yaml`
- **Symptom:** `deploy-edge-apps.sh` failed on `kubectl apply -k` for 509's `charts/base` directory.
- **Root cause:** No `kustomization.yaml` existed in the directory.
- **Fix:** Created the file with `apiVersion`, `kind`, and `resources` list.

### Fix 4 — gen-patch.sh ACR name extraction bug

- **File:** `src/500-application/507-ai-inference/charts/gen-patch.sh`
- **Symptom:** Generated patch files contained invalid image references.
- **Root cause:** Script parsed the wrong ACR name from Terraform output.
- **Fix:** Corrected ACR name extraction logic.

---

## ACR Authentication & Image Pull Issues

### Fix 5 — ACR 401 Unauthorized (ImagePullBackOff)

- **Symptom:** Pods entered `ImagePullBackOff` with `401 Unauthorized` when pulling images from ACR.
- **Root cause:** ACR required authentication but the cluster's pull credentials were not configured for private access in this deployment topology.
- **Fix:** Enabled anonymous pull on ACR via Terraform variable `acr_public_network_access_enabled = true`. ACR Premium SKU supports anonymous pull. This is acceptable for development/accelerator deployments.

### Fix 6 — Wrong ACR URL in patch files

- **File:** `src/500-application/507-ai-inference/charts/patch-containers.yaml`
- **Symptom:** Pods failed to pull images — registry hostname did not match the deployed ACR.
- **Root cause:** Hardcoded image reference pointed to the wrong ACR registry name.
- **Fix:** Corrected the image reference in `patch-containers.yaml`.

---

## Network & Connectivity Issues

### Fix 3 — Arc proxy connection drops

- **Symptom:** HTTPS_PROXY tunnel to Arc cluster (port 9800) dropped intermittently during long-running `kubectl` operations.
- **Root cause:** Arc proxy background process terminates silently under sustained load or idle timeouts.
- **Fix:** Operational workaround — monitor the Arc proxy background terminal and restart when the tunnel dies. No permanent code fix; this is an inherent characteristic of the Arc proxy mechanism.

---

## Storage & Volume Issues

### Fix 7 — PVC StorageClass mismatch

- **Symptom:** `PersistentVolumeClaim` for media-capture stayed in `Pending` state — no matching PV could bind.
- **Root cause:** Requested StorageClass did not exist on the cluster or was incorrect for the workload.
- **Fix:** Used `cloud-backed-sc` StorageClass (backed by Azure Container Storage Arc / ACSA) for `media-capture`. Used `local-path` for `ai-models-pvc` where cloud-backed storage is unnecessary.

---

## Application Container & Model Loading Issues

### Fix 8 — ai-edge-inference CrashLoopBackOff (model file missing)

- **Files:**
  - `src/500-application/507-ai-inference/charts/base/deployment.yaml`
  - `src/500-application/507-ai-inference/charts/model-downloader-job.yaml`
  - `blueprints/leak-detection/scripts/deploy-edge-apps.sh`
- **Symptom:** Pod logs: `ERROR: Failed to initialize inference engine: Model file does not exist: "/models/default.onnx"`
- **Root cause:** The init container was `busybox:1.35`, which lacks `curl`/`wget`. When it attempted to download ONNX models from Azure Blob Storage, it created README placeholder files (0-byte or HTML error pages) instead of actual model binaries.
- **Fix (3 parts):**
  1. Changed init container image from `busybox:1.35` to `curlimages/curl:latest` in `deployment.yaml`.
  2. Updated `model-downloader-job.yaml` to copy the model to a flat `default.onnx` path expected by the inference engine.
  3. Fixed `deploy-edge-apps.sh` model-downloader job path from `charts/base/model-downloader-job.yaml` to `charts/model-downloader-job.yaml`.

---

## Build Workflow Issues

### Fix 9 — ACR Build resource limits exceeded

- **See:** [`parker-local-docker-builds.md`](parker-local-docker-builds.md) in this inbox directory.
- **Summary:** 503-media-capture-service compiles FFmpeg, OpenCV, and Rust (~30 min build), which exceeded ACR Build server-side resource limits. Parker created a two-stage local Docker build + ACR push workflow. No duplication here — Parker's decision entry is the authoritative record.

---

## Lessons Learned

1. **Always use `${VAR:-}` defaults in `set -u` scripts.** Every script that sources environment variables must guard against unset vars. This is a recurring class of bug across the project.

2. **Validate Kustomize directories before merging.** Any directory referenced by `kubectl apply -k` must contain a `kustomization.yaml`. A CI check or pre-deploy validation step would catch this class of error early.

3. **Init containers must match their workload.** `busybox` cannot download files from HTTPS endpoints with TLS. When an init container needs to fetch artifacts, use an image with `curl` or `wget` (e.g., `curlimages/curl`).

4. **ACR image references are a multi-point failure.** ACR name extraction (gen-patch.sh), patch file contents (patch-containers.yaml), and Terraform outputs must all agree. A single source of truth for the ACR name — propagated through Terraform outputs into all scripts — would eliminate Fixes 4, 5, and 6.

5. **StorageClass names vary by cluster topology.** Never hardcode StorageClass names. Future work should query available StorageClasses or parameterize them in the blueprint variables.

6. **Arc proxy is operationally fragile.** Long-running deployments through Arc proxy require monitoring and restart capability. Deployment scripts should detect proxy failures and prompt for reconnection rather than failing silently.

7. **Server-side builds have hard limits.** ACR Build is not suitable for large compilation workloads (FFmpeg + OpenCV + Rust). Local builds or dedicated build agents are required for heavy images. Parker's two-stage workflow is the team standard going forward.

8. **Model provisioning needs first-class automation.** The ONNX model download was the single most complex failure (Fix 8) because it spanned three files and required understanding the full init-container → volume-mount → application-path chain. Model provisioning should be a tested, standalone step in the deployment pipeline.
