# Decision: 507-ai-inference Automation Gaps

**Proposed by:** Parker (Edge Developer)
**Date:** 2025-07-25
**Status:** PROPOSED

## Context

Deep technical analysis of `src/500-application/507-ai-inference/` revealed that while the service is fully implemented (dual ONNX/Candle backends, AIO SDK integration, Kustomize manifests, deploy script), it is not wired into the leak-detection blueprint or any automated deployment path.

The `industrial-safety.yaml` model config includes `"leak"` as a class label, confirming this service was designed for the leak detection use case.

## Gaps Requiring Decisions

### 1. Blueprint Integration

507 is not referenced in `blueprints/leak-detection/terraform/main.tf`. The blueprint creates an ACR and all edge infrastructure, but nothing pushes the 507 image or deploys its Kustomize manifests.

**Options:**

- **(A)** Add a Terraform module that applies the Kustomize manifests post-AIO-deployment (via `kubernetes_manifest` or `helm_release` if converted to Helm)
- **(B)** Add a post-deploy script step to the blueprint that runs `deploy.sh --deploy-only`
- **(C)** Adopt GitOps (Flux/ArgoCD already available via Arc extensions) to auto-sync from a manifest repo

**Recommendation:** Option A or C — delegates to Ripley.

### 2. Helm vs Kustomize Consistency

507 is the only application using Kustomize; 500, 503, 504, 506 all use Helm. This creates friction for:

- CI/CD pipeline assumptions (templates assume Helm or raw Docker)
- Blueprint integration (Terraform `helm_release` is established; `kubernetes_manifest` for Kustomize is not)
- Operator familiarity

**Options:**

- **(A)** Convert 507 to a Helm chart (aligns with all other apps)
- **(B)** Keep Kustomize and build blueprint integration around it

**Recommendation:** Option A — I (Parker) can create the Helm chart structure.

### 3. Health Probes Disabled

`charts/base/deployment.yaml` has all three probes (liveness, readiness, startup) commented out with the note "Temporarily disabled for debugging." This means Kubernetes cannot automatically restart unhealthy pods or exclude them from service endpoints.

**Action needed:** I will re-enable probes after confirming the health endpoint behavior.

### 4. Base Image Modernization

507 uses CBL-Mariner 2.0 while 501 and 503 use Azure Linux 3.0. The Dockerfile also pins exact package versions (`openssl-devel-1.1.1k-36.cm2`) that will fail when the Mariner 2.0 repository removes them.

**Action needed:** Migrate to Azure Linux 3.0 with dynamic package versions.

## Delegation Summary

| Action | Owner | Priority |
|--------|-------|----------|
| Blueprint integration for 507 | Ripley | High |
| Helm chart conversion (if decided) | Parker | Medium |
| Re-enable health probes | Parker | High |
| Base image migration to Azure Linux 3.0 | Parker | Medium |
| Model provisioning automation | Ripley + Parker | Medium |
| Parameterize hardcoded ACR references | Parker | Low |
