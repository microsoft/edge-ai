# Infrastructure Analysis — Leak Detection Application Deployment

**By:** Ripley (Infra Dev)
**Date:** 2025-07-25

## Context

Comprehensive infrastructure and deployment automation analysis for deploying leak detection application containers to the edge K3s cluster via the existing IaC framework. Covers: dependency chain, ACR configuration, Key Vault access, networking, existing build/push patterns, CI/CD patterns, and concrete Terraform/IaC proposals.

## Findings

### 1. Dependency Chain (14 Modules)

The leak-detection blueprint deploys in strict order:

1. `cloud_resource_group` (000) — resource group
2. `cloud_networking` (050) — VNet, subnet, NSG, NAT gateway
3. `cloud_security_identity` (010) — Key Vault, managed identities, RBAC
4. `cloud_observability` (020) — monitoring (Grafana, Log Analytics, Azure Monitor)
5. `cloud_data` (030) — storage, Schema Registry, ADR namespace
6. `cloud_messaging` (040) — Event Grid, Event Hubs
7. `cloud_notification` (045) — Logic App (gated by `should_create_teams_notification`)
8. `cloud_vm_host` (051) — Ubuntu VM for K3s
9. `cloud_acr` (060) — Azure Container Registry
10. `edge_cncf_cluster` (100) — K3s + Arc connection
11. `edge_arc_extensions` (109) — Arc extensions
12. `edge_iot_ops` (110) — AIO instance, connectors, registry endpoints
13. `edge_assets` (111) — devices and assets
14. `edge_observability` (120) + `edge_messaging` (130)

Application image deployment happens **after** step 12 — requires ACR, AIO instance, and registry endpoints all provisioned.

### 2. ACR Configuration

- **SKU:** Premium (default), required for private endpoints
- **Public access:** Disabled by default (`acr_public_network_access_enabled = false`)
- **Private endpoint:** Dedicated subnet with private DNS zone (`privatelink.azurecr.io`), VNet link, A records for registry and data endpoints
- **Auth mechanism:** No admin credentials. AIO extension's system-assigned managed identity receives `AcrPull` role via `registry-endpoints` module
- **Blueprint variable:** `should_include_acr_registry_endpoint` (default `false`) must be set to `true` for AIO to pull custom images
- **Key resource:** `azapi_resource.registry_endpoint` (type `Microsoft.IoTOperations/instances/registryEndpoints@2025-10-01`) with `SystemAssignedManagedIdentity` auth method

### 3. Key Vault Access

- **Authorization:** RBAC-based (`rbac_authorization_enabled = true`), no access policies
- **Edge access:** Secret Sync Extension with dedicated `secret_sync_identity` (user-assigned managed identity)
- **Admin access:** Secrets Officer role for current user
- **Private endpoint:** Optional, via `should_enable_private_endpoints` with private DNS zone (`privatelink.vaultcore.azure.net`)
- **Public access:** Configurable via `should_enable_key_vault_public_network_access` (default `true`)
- **Purge protection:** Disabled (`purge_protection_enabled = false`)

### 4. Networking

- **Topology:** Single VNet + single subnet + NSG + optional NAT gateway
- **Outbound:** NAT gateway provides managed outbound (gated by `should_enable_managed_outbound_access`)
- **Private DNS:** Zones for ACR (`privatelink.azurecr.io`), Key Vault (`privatelink.vaultcore.azure.net`), storage, linked to VNet
- **NSG rules:** No explicit rules for ACR/KV traffic — relies on private endpoints within VNet and Azure service tags
- **VM placement:** Edge VM sits in the VNet subnet, resolves private endpoints via DNS zone links
- **Private resolver:** Optional (`should_enable_private_resolver`) for DNS forwarding

### 5. Existing Build/Push Patterns

**No Terraform-native Docker build/push exists in this codebase.** All image builds are standalone bash scripts:

| Service | Script | Pattern |
|---------|--------|---------|
| 507-ai-inference | `scripts/deploy.sh` | `docker build` → `az acr login` → `docker push` → `kustomize` → `kubectl apply` |
| 503-media-capture | `scripts/deploy-media-capture-service.sh` | `docker build` → `az acr login` → `docker push` → `az connectedk8s proxy` → `helm install` |
| 506-ros2-connector | `scripts/deploy-ros2-simulator.sh` | `docker build` → `az acr login` → `docker push` → `helm install` |

### 6. Existing Terraform Execution Patterns

| Pattern | Location | Mechanism |
|---------|----------|-----------|
| Helm releases | `100-cncf-cluster/modules/arc-agents` | `helm_release` resource with OCI repository |
| Script execution | `110-iot-ops/modules/apply-scripts` | `terraform_data` + `local-exec` via `bash -c` with `az connectedk8s proxy` |
| Dashboard import | `020-observability/main.tf` | `terraform_data` + `local-exec` via `bash import-grafana-dashboards.sh` |

### 7. CI/CD Pattern

The `501-ci-cd` component uses the Kalypso/Flux GitOps pattern (three-repo: source, configs, gitops). Not directly applicable for inline Terraform-triggered builds but demonstrates the project's approach to continuous deployment via GitOps on Arc-connected clusters.

## Decisions Required

### D1: Application image build and push to ACR

**Options:**

**A. `terraform_data` + `local-exec` calling bash script (recommended)**
- Follows the `apply-scripts` and `observability` precedent
- Script performs: `docker build` → `az acr login` → `docker push`
- Triggered by `triggers_replace` on source hash or image tag
- Auth: `az acr login` uses the current Azure CLI session (same as existing deploy scripts)
- Private ACR: Works because Terraform runs from a machine with Azure CLI access; `az acr login` handles token exchange regardless of public endpoint status

**B. Separate bash script execution (current pattern for 503/507)**
- No Terraform integration — manual script execution
- Does not fit the "infrastructure-as-code deploys everything" model
- Requires separate operator action after `terraform apply`

**C. GitOps via 501-ci-cd Kalypso pattern**
- Full CI/CD pipeline with Flux reconciliation
- Heavyweight for a single blueprint deployment
- Best for multi-environment, continuous deployment scenarios

**Recommendation:** Option A for initial implementation. Option C for production maturity.

### D2: Helm chart deployment to edge cluster

**Options:**

**A. `helm_release` resource via `az connectedk8s proxy` (recommended)**
- Follows the `arc-agents` pattern using the Helm provider
- Requires proxy setup (same as `apply-scripts` module)
- Supports OCI-based Helm charts from ACR
- Terraform manages lifecycle (install, upgrade, rollback)

**B. `terraform_data` + `local-exec` calling `helm install`**
- Follows the `apply-scripts` bash execution pattern
- Less Terraform lifecycle management
- Simpler to implement initially

**Recommendation:** Option A for Terraform-managed lifecycle. The `arc-agents` module proves `helm_release` works with Arc-connected clusters.

### D3: Blueprint variable `should_include_acr_registry_endpoint` default

**Current:** `false`
**Proposed:** Set to `true` in the leak-detection blueprint (or override in tfvars)

**Rationale:** The leak detection pipeline requires custom container images (507-ai-inference, 503-media-capture). Without this, AIO cannot pull images from the private ACR. The `registry-endpoints` module automatically assigns AcrPull to the AIO extension's managed identity.

### D4: Secret management flow

**Current mechanism is sufficient:**
- Key Vault (RBAC) → Secret Sync Extension → K3s cluster secrets
- `secret_sync_identity` user-assigned managed identity already provisioned
- Logic App uses its own system-assigned identity for KV access
- No additional IaC needed for secret flow

### D5: Private networking constraints for image builds

**Key constraint:** ACR is private by default (`public_network_access_enabled = false`). Docker build/push from Terraform `local-exec` requires:

1. The Terraform execution environment must have Azure CLI access to the ACR (for `az acr login` token exchange)
2. If running from within the VNet (e.g., on the VM), private endpoint resolves correctly
3. If running from outside the VNet (e.g., CI/CD agent), either:
   - Temporarily enable public access
   - Use `acr_allowed_public_ip_ranges` to allowlist the CI agent IP
   - Use a self-hosted agent within the VNet

**Recommendation:** For blueprint-driven deployment, document the network prerequisite. For CI/CD, use `acr_allowed_public_ip_ranges` or a VNet-hosted agent.

## Status

PROPOSED
