# Decision: 507 AI Inference Edge Deployment Automation

**Author:** Dallas (Lead Architect)
**Date:** 2025-07-25
**Status:** Proposed
**Scope:** `blueprints/leak-detection`, `src/500-application/507-ai-inference`

## Context

The leak-detection blueprint deploys 15 Terraform modules covering cloud foundation through edge messaging, but stops short of deploying the 507 AI inference application workload. Today the 507 service requires manual execution of `deploy.sh` (334 lines) which handles Docker build, ACR push, Kustomize patch generation, and kubectl apply. The blueprint's ACR and Key Vault default to private access (`acr_public_network_access_enabled = false`).

## Problem

There is a "last mile" gap between infrastructure provisioned by Terraform and the running 507 application on the edge cluster. The gap includes:

1. **No automated Docker build/push** — `deploy.sh` runs `docker build` and `az acr login` + `docker push` manually
2. **No automated Kubernetes deployment** — Kustomize manifests applied manually via `kubectl apply -k`
3. **Private ACR constraint** — ACR public endpoint is disabled; build agents need network access or trusted service bypass
4. **AIO SDK private feed** — Docker build requires credentials for `aio-sdks` Azure DevOps Artifacts Cargo registry
5. **Model download from public GitHub** — The `model-downloader-job.yaml` fetches ONNX models from `github.com/onnx/models`, which won't work in air-gapped environments
6. **Kustomize vs Helm inconsistency** — 507 uses Kustomize while 500 and 503 use Helm charts

## Options

### Option A: CI/CD Pipeline (Azure DevOps / GitHub Actions)

Add a pipeline stage that runs after `terraform apply` completes. The pipeline:

- Builds the Docker image using the existing Dockerfile
- Pushes to the private ACR (pipeline identity has AcrPush role)
- Connects to the Arc cluster via `az connectedk8s proxy`
- Applies Kustomize manifests with patched image references

**Pros:** Clean separation of IaC and app deployment; pipeline identity handles ACR auth; retryable independently; audit trail.
**Cons:** Requires pipeline infrastructure; two-step deployment; Arc proxy management in CI.

### Option B: Terraform `terraform_data` with `local-exec` Provisioner

Extend the blueprint with a `terraform_data` resource (like `dual-peered-single-node-cluster/modules/apply-scripts`) that:

- Sources `init-scripts.sh` to establish Arc proxy
- Runs a deployment script that builds, pushes, and applies

**Pros:** Single `terraform apply` deploys everything; uses existing `apply-scripts` pattern; blueprint outputs (ACR name, cluster connection) are directly available.
**Cons:** Docker build during Terraform apply is slow and fragile; conflates infrastructure and application lifecycle; re-runs on every apply unless carefully guarded with triggers.

### Option C: Arc GitOps (Flux) Configuration

Add a `azurerm_kubernetes_flux_configuration` resource to the blueprint that:

- Points to a Git repo branch containing the Kustomize manifests
- Kustomize patches are pre-generated with the correct ACR image reference
- Flux reconciles automatically on push

**Pros:** Declarative; self-healing; standard GitOps pattern; works with private ACR via AIO registry endpoints.
**Cons:** Requires Flux extension on Arc cluster; image must be pre-built and pushed to ACR before GitOps can pull; adds Flux operational overhead; still needs a separate build/push mechanism.

### Option D: Hybrid — CI/CD Build + Terraform Deploy (Recommended)

Split the problem:

1. **CI/CD pipeline** handles Docker build and ACR push (self-hosted agent or ACR Tasks for private networking)
2. **Blueprint Terraform** adds a `terraform_data` provisioner module that deploys the Kustomize manifests to the cluster via Arc proxy (reusing the existing `apply-scripts` pattern from `110-iot-ops`)

The blueprint gains:

- A `should_deploy_ai_inference` feature flag (default: `false`)
- Variables for `ai_inference_image_tag` and `ai_inference_acr_name`
- A deploy module that sources `init-scripts.sh`, generates Kustomize patches with correct ACR/image, and runs `kubectl apply -k`
- `should_include_acr_registry_endpoint` defaults to `true` when `should_deploy_ai_inference` is `true`

**Pros:** Each tool does what it's best at; existing patterns reused; single `terraform apply` for infra + app deploy; image build is decoupled and can run in a self-hosted agent with VNet access to private ACR.
**Cons:** Slightly more complex than pure CI/CD; deploy script in Terraform is still imperative.

## Recommendation

**Option D (Hybrid)** — it aligns with the existing `apply-scripts` pattern already used in `110-iot-ops` and `dual-peered-single-node-cluster`, keeps Docker build in CI/CD where it belongs, and delivers single-command deployment for infrastructure + application.

## Key Technical Details

### Private ACR Access (Solved)

The edge cluster pulls images from private ACR via AIO's `registry_endpoints` mechanism:

- `acr_registry_endpoint` local in `main.tf` creates an AIO registry endpoint with `SystemAssignedManagedIdentity` auth
- `should_assign_acr_pull_for_aio = true` grants AcrPull role to the AIO extension identity
- This is already wired but gated by `should_include_acr_registry_endpoint` (default: `false`)

For CI/CD build/push, options include:

- **ACR Tasks** (`az acr build`) — runs in ACR's own compute, no VNet needed
- **Self-hosted agent** in the same VNet as ACR's private endpoint
- **Trusted services bypass** — `acr_allow_trusted_services = true` (already defaulted)

### Arc Proxy for kubectl Access (Solved)

The `init-scripts.sh` (267 lines) already handles:

- `az connectedk8s proxy` lifecycle with race condition fixes
- Temporary kubeconfig with atomic file moves
- Cleanup on exit/interrupt
- Optional Key Vault token-based authentication

### Model Download (Gap)

The `model-downloader-job.yaml` fetches from public GitHub URLs. For private/air-gapped environments, models should be:

- Pre-packaged in the Docker image, or
- Stored in Azure Blob Storage and downloaded via managed identity, or
- Stored in ACR as OCI artifacts

## Implementation Phases

1. **Phase 1 — Enable ACR registry endpoint:** Set `should_include_acr_registry_endpoint = true` by default when deploying 507
2. **Phase 2 — CI/CD image build:** Pipeline stage with `az acr build` or self-hosted agent
3. **Phase 3 — Blueprint deploy module:** `terraform_data` provisioner for Kustomize apply via Arc proxy
4. **Phase 4 — Model management:** Move models from public GitHub to ACR OCI artifacts or blob storage
