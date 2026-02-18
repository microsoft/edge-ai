# Decision: ACR and Dockerfile Deployment Challenges

**Proposed by:** Carlos Sardo (user directive)
**Date:** 2025-07-25
**Status:** PROPOSED

---

### ACR public network access required for `az acr build` workflows

**By:** Carlos Sardo (user directive)

**What:** When using `az acr build` (server-side builds), the ACR must have public network access enabled. The leak-detection blueprint defaults `acr_public_network_access_enabled=false` (secure-by-default). The Microsoft-hosted ACR Build agent runs outside the VNet and cannot reach a private-only ACR endpoint. The deploy used `-var 'acr_public_network_access_enabled=true'` to unblock.

**Why:** ACR Build tasks execute on Microsoft-hosted ephemeral VMs that do not have VNet connectivity to the private ACR endpoint. The `build-app-images.sh` script invoked via `terraform_data.acr_image_builds` uses `az acr build`, which offloads the Docker build to this hosted service. Without public network access (or IP whitelisting), the build agent cannot push images to the registry.

---

### 507-ai-inference Dockerfile cross-compilation scaffolding removed for ACR Build compatibility

**By:** Carlos Sardo (user directive)

**What:** The `FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx` stage and related `--platform=$BUILDPLATFORM`, `COPY --from=xx / /`, and `ARG TARGETPLATFORM` directives were removed from `src/500-application/507-ai-inference/services/ai-edge-inference/Dockerfile`. ACR Build's dependency scanner cannot parse `--platform=$BUILDPLATFORM` variable syntax in FROM lines (it performs static analysis, not runtime evaluation).

**Why:** ACR Build Run ID `ch3` failed in 3 seconds at the dependency scanning phase with `"unable to understand line FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx"`. The cross-compilation scaffolding was for future multi-architecture support but is not functionally needed for ACR Build on amd64. Removing it enables ACR Build compatibility with no functional impact. The 503-media-capture-service Dockerfile was cross-checked and is already compatible.
