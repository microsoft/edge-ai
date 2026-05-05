---
title: Upgrade Azure IoT Operations
description: How to upgrade Azure IoT Operations (AIO) and reconcile the upgrade with the edge-ai Terraform or Bicep deployments
author: Edge AI Team
ms.date: 2026-05-05
ms.topic: how-to
estimated_reading_time: 5
keywords:
  - azure iot operations
  - aio upgrade
  - terraform
  - bicep
  - cert-manager
  - secret store
---

## Upgrade Azure IoT Operations

This guide describes how to upgrade an Azure IoT Operations (AIO) instance deployed by edge-ai and how to reconcile the upgrade with your Infrastructure as Code (IaC) of choice.

The `az iot ops upgrade` command updates three cluster components when newer stable versions are available:

- `certManager`
- `secretStore`
- `iotOperations`

The reconciliation steps differ between Terraform (stateful) and Bicep (stateless).

## Prerequisites

- Azure CLI logged in to the target subscription.
- `azure-iot-ops` CLI extension installed (this repo expects version `2.4.0`).
- `<RESOURCE_GROUP_NAME>` — the resource group containing the AIO instance.
- `<INSTANCE_NAME>` — the AIO instance name (for edge-ai blueprints this is typically `iotops-arck-<resource_prefix>-<environment>-<instance>`).

## Run the AIO upgrade

Run the upgrade against your existing AIO instance. Review the proposed changes and confirm:

```bash
az iot ops upgrade \
  --resource-group <RESOURCE_GROUP_NAME> \
  --name <INSTANCE_NAME>
```

The CLI prints a table comparing current and desired versions for `certManager`, `secretStore`, and `iotOperations`, then performs the update.

After this point, Azure has been mutated — the steps below bring your IaC back in sync.

## Reconcile with Terraform

Terraform is stateful. The state file holds the previous extension versions; after `az iot ops upgrade` it no longer matches Azure. Refresh state, verify, then re-apply your blueprint at the latest edge-ai versions.

1. Refresh state from Azure to absorb the new versions:

   ```bash
   cd blueprints/<your-blueprint>/terraform
   source ../../../scripts/az-sub-init.sh
   terraform apply -refresh-only -var-file=terraform.tfvars
   ```

   Confirm when prompted. Terraform updates the in-state `version` attribute for the three extensions to match what Azure now reports.

2. Verify there is no drift on the upgraded components:

   ```bash
   terraform plan -var-file=terraform.tfvars | grep -E "cert_manager|secret_store|iot_operations"
   ```

   No output (or `No changes`) means the IaC and Azure agree on the new versions.

3. Re-run edge-ai with the latest AIO version pins and any updated components.

   - Pull the latest edge-ai changes (which may bump the version defaults in [variables.init.tf](../../src/100-edge/110-iot-ops/terraform/variables.init.tf), [variables.instance.tf](../../src/100-edge/110-iot-ops/terraform/variables.instance.tf), and [variables.tf](../../src/100-edge/109-arc-extensions/terraform/variables.tf)).
   - Apply the blueprint:

     ```bash
     terraform apply -var-file=terraform.tfvars
     ```

   If the upstream pins are now newer than what `az iot ops upgrade` installed, Terraform will move the cluster to the newer pins. If they match, the apply is a no-op for the AIO extensions.

> If you skip step 1, the next `terraform apply` will detect "drift" on the three extensions and roll Azure back to the versions pinned in code. Always run `-refresh-only` first when you upgraded out-of-band.

## Reconcile with Bicep

Bicep is stateless — there is no per-deployment record of previously applied versions to reconcile. After `az iot ops upgrade` no further ARM operations are required to "import" the new state. Subsequent Bicep deployments are idempotent against whatever exists in Azure.

1. Run the AIO upgrade as shown above.

2. Re-run edge-ai with the latest AIO version pins and any updated components.

   - Pull the latest edge-ai changes (which may bump the defaults in [109-arc-extensions/bicep/types.bicep](../../src/100-edge/109-arc-extensions/bicep/types.bicep) and [110-iot-ops/bicep/types.bicep](../../src/100-edge/110-iot-ops/bicep/types.bicep)).
   - Re-deploy your blueprint with `az deployment group create` (or your existing pipeline) using the same parameters.

   If the parameter values are equal to or newer than what `az iot ops upgrade` installed, ARM applies the new versions. Otherwise the deployment is a no-op for the AIO extensions.

> Because Bicep / ARM compares declared properties to live resource state, you do not need a refresh, import, or state-edit step. The next deployment is the reconciliation.

## Troubleshooting

- **Terraform plan still shows version diffs after `-refresh-only`**: confirm that the `azurerm_arc_kubernetes_cluster_extension` resources for `cert_manager`, `secret_store`, and `iot_operations` in state now show the upgraded `version`. If they do, the diff is being driven by code defaults newer than what `az iot ops upgrade` installed — running `terraform apply` will move Azure to those defaults.
- **`az iot ops upgrade` reports no updates**: the cluster is already on the latest stable channel for all three components; nothing to reconcile.
- **Permission errors during refresh**: ensure your principal has read access on the connected cluster, the cluster extensions, and the AIO instance resource group.
