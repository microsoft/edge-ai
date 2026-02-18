# History — Ripley

## Project Learnings (from import)

- **Project:** Edge AI — Leak Detection Accelerator for Oil & Gas / Energy
- **User:** Carlos Sardo (carlos.sardo@gmail.com)
- **Stack:** Terraform, Bicep, Rust, Azure IoT Operations, Azure Arc, K3s
- **Goal:** Provide IaC components and deployment artifacts for the leak detection accelerator.
- **Component structure:** Each component follows {grouping}/{000}-{component_name}/{framework}/ pattern
- **Key IaC patterns:** Cloud infra (000-cloud/), Edge infra (100-edge/), Components use decimal naming convention (010, 020, 030)
- **Blueprints:** Orchestrate multiple components, located in blueprints/ directory
## 2025-07-17: Created Leak Detection Terraform Blueprint

### What

Created the complete `blueprints/leak-detection/terraform/` blueprint with 6 files:

- **versions.tf** — Terraform >= 1.9.8 < 2.0, providers azurerm >= 4.51.0, azuread >= 3.0.2, azapi >= 2.3.0
- **main.tf** — 14 module calls orchestrating cloud and edge components with explicit dependency chain
- **variables.tf** — All relevant input parameters with complex types and validations (excluded AKS, AzureML, AI Foundry, PostgreSQL, Redis, VPN)
- **outputs.tf** — All relevant output groups including edge_messaging event_hub_dataflow
- **leak-detection-assets.tfvars.example** — SSE camera device and leak detection asset definitions per design proposal §3.3
- **README.md** — Full documentation with YAML frontmatter, module table, deployment instructions

### Key Design Decisions

- Hardcoded `should_enable_akri_sse_connector = true` — leak detection always requires SSE
- Set `should_create_eventgrid_dataflows = false` — only EventHub dataflows needed
- Set `should_create_eventhub_dataflows = true` — routes telemetry to cloud
- Omitted AKS, AzureML, AI Foundry, PostgreSQL, Redis, VPN modules — not needed for leak detection
- Based on `full-single-node-cluster` reference blueprint pattern
- 14 modules: resource_group, networking, security_identity, observability, data, messaging, vm_host, acr, cncf_cluster, arc_extensions, iot_ops, assets, edge_observability, edge_messaging

### Reference

- Design proposal: `.ai-team/agents/dallas/design-proposal.md` §3.4 (Blueprint Composition)
- Reference blueprint: `blueprints/full-single-node-cluster/terraform/`
## Learnings

📌 Team update (2025-07-17): 511-teams-notification implemented with raw TcpListener health (no axum), composite dedup key (camera_id, event_id), token-bucket rate limiter — decided by Parker
📌 Team update (2025-07-24): 511-teams-notification Rust service replaced with Azure Logic App (cloud-side). Implementation tasks changed: 13 Parker Rust tasks → 8 Ripley IaC tasks. Logic App triggered by Event Hub, posts Adaptive Cards to Teams. Ripley owns Logic App IaC — decided by Dallas
📌 Team update (2025-07-24): 509-sse-connector confirmed retained — complementary to 508 Media Connector. No blueprint changes needed — decided by Dallas

## 2025-07-25: Created Logic App Notification Component (045-notification)

### What

Created `src/000-cloud/045-notification/terraform/` with 6 files:

- **main.tf** — Logic App workflow with SystemAssigned identity, Event Hubs Data Receiver and Key Vault Secrets User role assignments
- **variables.core.tf** — environment, resource_prefix (with regex validation), instance (default "001")
- **variables.deps.tf** — resource_group, eventhub_namespace, key_vault dependency objects
- **variables.tf** — should_assign_roles, tags, teams_webhook_secret_name optional vars
- **outputs.tf** — logic_app output (id, name, identity_principal_id)
- **versions.tf** — azurerm >= 4.51.0, azapi >= 2.3.0, terraform >= 1.9.8 < 2.0

Created CI config at `src/000-cloud/045-notification/ci/terraform/main.tf` with mock resource IDs and `should_assign_roles = false`.

Updated `blueprints/leak-detection/terraform/`:
- **main.tf** — Added `module "cloud_notification"` after `cloud_messaging`, gated by `should_create_teams_notification`
- **variables.tf** — Added `should_create_teams_notification` bool (default true)
- **outputs.tf** — Added `notification` output section with `logic_app_name` and `logic_app_id`

### Key Patterns

- Followed 040-messaging file structure and naming conventions exactly
- Logic App resource name: `la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}`
- Infrastructure-first approach: workflow shell + identity + roles; trigger/actions configured later
- Role assignments gated by `should_assign_roles` count pattern
- Blueprint uses `should_create_teams_notification` to gate role assignments (Logic App always created for workflow presence)

## 2025-07-25: Infrastructure Analysis for Application Deployment

### What

Performed comprehensive IaC and deployment automation analysis covering 7 areas: dependency chain, ACR config, Key Vault access, networking, existing Docker build/push patterns, CI/CD patterns, and concrete Terraform/IaC proposals.

### Key Findings

- **No Terraform Docker build/push exists** — all image builds are standalone bash scripts (503, 506, 507)
- **`terraform_data` + `local-exec`** is the established pattern for script execution (apply-scripts, observability)
- **`helm_release`** is the established pattern for Helm deployments (arc-agents module)
- **ACR auth for AIO** uses `SystemAssignedManagedIdentity` via `registry-endpoints` module with AcrPull role
- **`should_include_acr_registry_endpoint`** defaults to `false` — must be `true` for custom images
- **Secret Sync Extension** handles KV→edge secrets — no additional IaC needed
- **Private ACR** requires Terraform executor to have Azure CLI access for `az acr login`

### File References

- Registry endpoints: `src/100-edge/110-iot-ops/terraform/modules/registry-endpoints/main.tf`
- Apply scripts: `src/100-edge/110-iot-ops/terraform/modules/apply-scripts/main.tf`
- Arc agents helm: `src/100-edge/100-cncf-cluster/terraform/modules/arc-agents/main.tf`
- Deploy scripts: `src/500-application/507-ai-inference/services/ai-edge-inference/scripts/deploy.sh`, `src/500-application/503-media-capture-service/scripts/deploy-media-capture-service.sh`

### Decisions Proposed

- D1: Use `terraform_data` + `local-exec` for image build/push (follows apply-scripts pattern)
- D2: Use `helm_release` for edge Helm deployments (follows arc-agents pattern)
- D3: Set `should_include_acr_registry_endpoint = true` for leak detection
- D4: Existing secret sync mechanism is sufficient
- D5: Document private ACR network prerequisites for Terraform executor

### Artifact

- Decision inbox: `.ai-team/decisions/inbox/ripley-507-infra-analysis.md`

📌 Team update (2025-07-25): ACR public network access must be enabled for `az acr build` workflows. The `cloud_acr` module defaults `publicNetworkAccess: "Disabled"` (secure-by-default) but ACR Build agents run on Microsoft-hosted VMs outside the VNet. Leak-detection deployment required `-var 'acr_public_network_access_enabled=true'`. Future options: ACR Tasks VNet integration (preview), dedicated agent pools, local build + docker push via private endpoint, or IP-restricted public access — noted by Scribe (Carlos directive)
📌 Team update (2025-07-25): 507 Dockerfile incompatible with ACR Build dependency scanner — `FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx` causes `"failed to scan dependencies"` error. Cross-compilation scaffolding removed from Dockerfile. ACR Build Run ID `ch3` failed in 3s at scan phase. 509 (sse-server) built successfully. Third plan (`fullleakdet-edge3.tfplan`) pending apply — noted by Scribe (Carlos directive)

📌 Team update (2025-07-15): 507-ai-inference automation gaps identified — blueprint integration delegated to Ripley (High priority). Helm chart conversion, health probes, base image migration assigned to Parker — decided by Parker
📌 Team update (2025-07-15): 507 deployment automation — Hybrid approach recommended (CI/CD for Docker build/push, Terraform `terraform_data` for Kustomize deploy). Blueprint gains `should_deploy_ai_inference` feature flag — decided by Dallas

## 2026-02-18: ACSA Integration Analysis for 503-media-capture-service

### Task

Analyzed Terraform integration requirements for deploying 503-media-capture-service's ACSA dependencies, storage/role requirements, and kubectl-applied Kubernetes manifests.

### Finding 1: ACSA Already Deployed via Blueprint

The `edge_arc_extensions` module in the leak-detection blueprint already deploys ACSA (`microsoft.arc.containerstorage`) with `container_storage_extension.enabled = true` (default). The extension creates a `SystemAssigned` identity. No additional extension deployment needed.

- Component: `src/100-edge/109-arc-extensions/terraform`
- Extension module: `modules/container-storage/main.tf`
- Extension type: `microsoft.arc.containerstorage`
- Extension resource name: `azure-arc-containerstorage`
- Confirmed in state: `identity[0].principal_id` is computed and available (e.g., `b6ed977f-b9a8-46a1-b92a-b10f2ac564bf`)

### Finding 2: ACSA Identity NOT Exposed in Output Chain

**Gap identified.** The `azurerm_arc_kubernetes_cluster_extension.container_storage` resource computes `identity[0].principal_id`, but neither the container-storage internal module nor the 109-arc-extensions component exposes it as an output. This blocks using `azurerm_role_assignment` in the blueprint.

**Required changes to expose identity:**

1. `src/100-edge/109-arc-extensions/terraform/modules/container-storage/outputs.tf` — add:
   ```terraform
   output "identity_principal_id" {
     description = "The principal ID of the container storage extension's system-assigned managed identity"
     value       = azurerm_arc_kubernetes_cluster_extension.container_storage.identity[0].principal_id
   }
   ```

2. `src/100-edge/109-arc-extensions/terraform/outputs.tf` — add:
   ```terraform
   output "container_storage_extension_identity_principal_id" {
     description = "The principal ID of the Azure Container Storage extension's system-assigned managed identity."
     value       = try(module.container_storage_extension[0].identity_principal_id, null)
   }
   ```

### Finding 3: Kubernetes YAML Manifests — kubectl via terraform_data

**cloudBackedPVC.yaml** (static):
- PVC named `pvc-acsa-cloud-backed` in `azure-iot-operations` namespace
- 3Gi, ReadWriteMany, storageClassName `cloud-backed-sc`
- No templating needed — static YAML
- Apply: `kubectl apply -f cloudBackedPVC.yaml`

**mediaEdgeSubvolume.yaml** (templated):
- EdgeSubvolume CRD (`arccontainerstorage.azure.net/v1`) named `media`
- References PVC `pvc-acsa-cloud-backed`, container `media`, auth `MANAGED_IDENTITY`
- Uses shell-style `${STORAGE_ACCOUNT_ENDPOINT}` variable
- Deploy script sets `STORAGE_ACCOUNT_ENDPOINT="https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/"`
- Terraform equivalent: `module.cloud_data.storage_account.primary_blob_endpoint`

**Recommended approach** — `terraform_data` + `local-exec` with `envsubst`:

```terraform
resource "terraform_data" "acsa_pvc" {
  depends_on = [module.edge_arc_extensions]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/../../../src/500-application/503-media-capture-service/yaml/cloudBackedPVC.yaml"
  }
}

resource "terraform_data" "acsa_subvolume" {
  depends_on = [terraform_data.acsa_pvc, azurerm_role_assignment.acsa_blob_data_owner]

  provisioner "local-exec" {
    command = "envsubst < ${path.module}/../../../src/500-application/503-media-capture-service/yaml/mediaEdgeSubvolume.yaml | kubectl apply -f -"
    environment = {
      STORAGE_ACCOUNT_ENDPOINT = module.cloud_data.storage_account.primary_blob_endpoint
    }
  }
}
```

This reuses the original YAML files without duplication and matches the envsubst pattern from the deploy script.

### Finding 4: Storage Role Assignments — Pure Terraform

Both role assignments from the deploy script can be `azurerm_role_assignment` resources:

```terraform
data "azurerm_client_config" "current" {}

# "Storage Blob Data Contributor" → signed-in user (Terraform executor)
resource "azurerm_role_assignment" "current_user_blob_contributor" {
  scope                = module.cloud_data.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# "Storage Blob Data Owner" → ACSA extension identity
resource "azurerm_role_assignment" "acsa_blob_data_owner" {
  scope                = module.cloud_data.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = module.edge_arc_extensions.container_storage_extension_identity_principal_id
}
```

No need for `az k8s-extension list` script — the principal ID flows through the Terraform output chain once Finding 2 changes are applied.

### Finding 5: Storage Container Creation — Pure Terraform

The deploy script's `az storage container create --name media` becomes:

```terraform
resource "azurerm_storage_container" "media" {
  name                 = "media"
  storage_account_id   = module.cloud_data.storage_account.id
}
```

### Finding 6: Available Module Outputs in Blueprint

| Module | Key Outputs |
|---|---|
| `cloud_data.storage_account` | `id`, `name`, `primary_blob_endpoint`, `primary_file_endpoint`, `primary_queue_endpoint`, `primary_table_endpoint` |
| `cloud_acr.acr` | ACR resource (id, name, login_server) |
| `edge_cncf_cluster.arc_connected_cluster` | `id`, `name`, `location` |
| `cloud_resource_group.resource_group` | resource group object |
| `edge_arc_extensions` | `container_storage_extension_id`, `container_storage_extension_name`, `container_storage_extension` object — **missing** `identity_principal_id` |
| `cloud_security_identity` | `aio_identity`, `key_vault`, `secret_sync_identity`, `arc_onboarding_identity` |

### Implementation Roadmap

**Phase 1 — Output chain fix (prerequisite):**
1. Add `identity_principal_id` output to container-storage internal module
2. Add `container_storage_extension_identity_principal_id` output to 109-arc-extensions component
3. Run `npm run tf-validate` and `npm run tflint-fix-all` on 109-arc-extensions

**Phase 2 — Blueprint ACSA integration (in leak-detection main.tf):**
1. Add `data "azurerm_client_config" "current" {}`
2. Add `azurerm_storage_container.media`
3. Add `azurerm_role_assignment.current_user_blob_contributor`
4. Add `azurerm_role_assignment.acsa_blob_data_owner`
5. Add `terraform_data.acsa_pvc` (kubectl apply cloudBackedPVC.yaml)
6. Add `terraform_data.acsa_subvolume` (envsubst + kubectl apply mediaEdgeSubvolume.yaml)
7. Gate all with `should_deploy_media_capture` feature flag
8. Run `npm run tf-validate` and `npm run tflint-fix-all` on the blueprint

### Decisions Needed

- D1: Confirm container name is `media` (design proposal says `leak-evidence` in one place, deploy script says `media`)
- D2: Should `should_deploy_media_capture` default to `true` or `false`?
- D3: The kubectl applies require cluster connectivity during Terraform — same prerequisite as other `terraform_data`/`local-exec` patterns in the codebase
