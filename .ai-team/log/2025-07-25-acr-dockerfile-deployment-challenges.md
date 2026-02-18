# Session — ACR and Dockerfile Deployment Challenges

- **Date:** 2025-07-25
- **Requested by:** Carlos Sardo
- **Project:** Edge AI — Leak Detection Accelerator

## Summary

During the leak-detection blueprint deployment (`resource_prefix=fullleakdet`, `environment=dev`, `location=eastus2`), two critical deployment challenges were encountered when enabling edge applications (`should_deploy_edge_applications=true`). Base infrastructure (95 resources) deployed successfully. Both challenges relate to ACR Build service interactions with blueprint defaults and Dockerfile patterns.

## Challenge 1 — ACR Firewall Blocking Build Agent

### Symptom

`az acr build` in `build-app-images.sh` returned connection errors. The Microsoft-hosted ACR Build agent (IP `104.208.200.3`) could not reach the ACR endpoint `acrfullleakdetdev001.azurecr.io`.

### Root Cause

The `cloud_acr` module (`src/000-cloud/060-acr/`) creates ACR with `publicNetworkAccess: "Disabled"` by default — this is the secure-by-default design. The blueprint variable `acr_public_network_access_enabled` defaults to `false`.

ACR Build tasks run on Microsoft-hosted infrastructure OUTSIDE the VNet. They need public network access to push images to the registry. The `terraform_data.acr_image_builds[0]` resource at `main.tf` line 296-319 runs `build-app-images.sh` via `local-exec` provisioner (line 303). The script uses `az acr build` which offloads the Docker build to ACR Build service — NOT a local Docker build. The build agent is a Microsoft-hosted ephemeral VM, not the Terraform executor.

### Solution

Added `-var 'acr_public_network_access_enabled=true'` to the terraform plan/apply command. The ACR updated in-place in ~12 seconds.

### Lesson Learned

When using `az acr build` (server-side builds), the ACR MUST have public network access enabled OR the ACR Build agent's IP range must be whitelisted. This is a fundamental tension between secure-by-default ACR configuration and ACR Build's architecture.

Future options:

1. Use ACR Tasks with VNet integration (preview)
2. Use dedicated agent pools with VNet connectivity
3. Build locally and `docker push` through private endpoint
4. Keep public access enabled but restrict to specific IP ranges

### Files Involved

- `blueprints/leak-detection/terraform/main.tf` — lines 149-175 (cloud_acr module), lines 296-319 (acr_image_builds)
- `blueprints/leak-detection/terraform/variables.tf` — line 348 (acr_public_network_access_enabled)
- `blueprints/leak-detection/scripts/build-app-images.sh` — build script using `az acr build`
- `src/000-cloud/060-acr/terraform/` — ACR component module

## Challenge 2 — 507-ai-inference Dockerfile Incompatible with ACR Build Dependency Scanner

### Symptom

After fixing the ACR firewall, the second `terraform apply` ran `build-app-images.sh`. The first image (509-sse-connector / `sse-server`) built successfully. The second image (507-ai-inference / `ai-edge-inference`) FAILED.

ACR Build Run ID `ch3` failed after only 3 seconds during the dependency scanning phase (before the actual Docker build started).

Error message:

```text
"unable to understand line FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx"
"failed to scan dependencies: exit status 1"
```

### Root Cause

The 507-ai-inference Dockerfile at `src/500-application/507-ai-inference/services/ai-edge-inference/Dockerfile` used a multi-platform cross-compilation pattern:

```dockerfile
FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx
```

This stage imports the `tonistiigi/xx` helper for cross-compiling Rust binaries to different architectures. Later lines used:

```dockerfile
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:... AS build
COPY --from=xx / /
ARG TARGETPLATFORM
```

ACR Build's dependency scanner runs BEFORE the actual Docker build. It parses Dockerfile FROM lines to resolve image dependencies. The scanner cannot handle:

1. `--platform=$BUILDPLATFORM` variable syntax (expects literal platform values or no platform flag)
2. The combination of the platform variable with the `tonistiigi/xx:master` image reference

This is a known limitation of ACR Build's dependency scanning — it performs static analysis, not runtime evaluation, so build-arg substitution does not happen at scan time.

### Solution

Applied edits to the 507 Dockerfile:

1. Removed the entire `tonistiigi/xx` cross-compilation stage (`FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx`)
2. Removed `--platform=$BUILDPLATFORM` from the build stage FROM line — changed to plain `FROM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:...`
3. Removed `COPY --from=xx / /` and `ARG TARGETPLATFORM` from the build stage body

### Rationale

The cross-compilation scaffolding was for future multi-architecture support but is NOT functionally needed for ACR Build, which runs natively on amd64. Removing it simplifies the Dockerfile (166 to ~163 lines) with no functional impact.

### Cross-check with Other Dockerfiles

The 503-media-capture-service Dockerfile was checked and found clean — it uses `ARG BUILDPLATFORM=linux/amd64` but does NOT use `--platform=` in FROM lines, so it is compatible with ACR Build.

### Files Involved

- `src/500-application/507-ai-inference/services/ai-edge-inference/Dockerfile` — MODIFIED (uncommitted)
- `src/500-application/503-media-capture-service/` Dockerfile — checked, clean
- `blueprints/leak-detection/scripts/build-app-images.sh` — builds 3 images: 509, 507, 503

## Current State After Fixes

| Item | Status |
|------|--------|
| ACR `acrfullleakdetdev001` | Public network access ENABLED |
| 507 Dockerfile | MODIFIED (cross-compilation removed), NOT YET COMMITTED |
| `sse-server:latest` image | Successfully pushed to ACR (second apply attempt) |
| Third terraform plan | `fullleakdet-edge3.tfplan` — 2 to add, 0 to change, 1 to destroy |
| Third terraform apply | NOT YET STARTED |

## Decisions Produced

| Decision | Status |
|----------|--------|
| ACR public network access must be enabled for `az acr build` workflows | PROPOSED |
| 507 Dockerfile cross-compilation scaffolding removed for ACR Build compatibility | PROPOSED |
