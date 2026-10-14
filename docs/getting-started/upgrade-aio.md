---
title: Upgrade Azure IoT Operations
description: How to upgrade Azure IoT Operations (AIO) and reconcile the upgrade with the edge-ai Terraform or Bicep deployments
author: Edge AI Team
ms.date: 2026-10-14
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

## Version matrix

This repository currently targets the **AIO 2609** release. The table below maps `az iot ops` CLI versions to the component versions pinned in edge-ai:

| CLI extension (`azure-iot-ops`) | AIO release | cert-manager | secret-sync-controller | iotOperations |
|---------------------------------|-------------|--------------|------------------------|---------------|
| 2.10.0                          | 2609        | 1.1.2        | 1.5.3                  | 1.4.112       |
| 2.9.0                           | 2608        | 1.0.0        | 1.5.2                  | 1.4.73        |
| 2.8.0                           | 2607        | 0.14.0       | 1.5.1                  | 1.4.41        |

For the full upstream compatibility matrix, see [Supported versions — Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-upgrade?tabs=portal#supported-versions).

## Prerequisites

- Azure CLI logged in to the target subscription.
- `azure-iot-ops` CLI extension installed (this repo expects version `2.10.0`).
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

Terraform compares configuration with refreshed resource state during a normal plan. A refresh-only apply records out-of-band changes in state and root outputs; it does not change configuration or remote resources. It cannot guarantee that the next normal plan is a no-op or prevent a downgrade to older configured versions.

1. Align the effective configuration with the versions installed by `az iot ops upgrade` before any normal apply.
   Use a matching edge-ai release or override its version inputs. Higher pins request another upgrade; lower pins can request a downgrade even after refresh-only.

2. Back up the selected workspace's state in a private location outside version control, then review a refresh-only operation:

   ```bash
   cd "blueprints/<your-blueprint>/terraform"
   source ../../../scripts/az-sub-init.sh
   terraform workspace show
   umask 077
   STATE_BACKUP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/edge-ai-upgrade.XXXXXX")
   terraform state pull > "$STATE_BACKUP_DIR/before-refresh.tfstate"
   ```

   Stop if the backup command fails or the selected workspace is not the intended deployment. Retain the backup securely; Terraform state can contain secrets. Then run:

   ```bash
   terraform apply -refresh-only -var-file=terraform.tfvars
   ```

   Confirm only after reviewing all proposed state and output changes. Unexpected missing resources or lookup errors need investigation, not approval of a refresh that forgets resources.

3. Inspect the complete normal plan:

   ```bash
   terraform plan -var-file=terraform.tfvars
   ```

   Do not filter the plan to AIO extension names: that hides changes to role assignments, custom locations, storage, and other dependencies. Confirm that upgraded components have no unintended version changes, cluster identity is known, and existing bootstrap secrets and VM setup payloads are unchanged. Stop on unexpected replacements or deletions and examine the attributes marked as forcing replacement.

4. Review remaining configuration drift separately. Only a successful full plan reporting `No changes` establishes a no-op. If intentional changes remain, approve them through your normal deployment process and review a fresh plan before applying; do not apply the whole blueprint merely to finish a refresh.

> [!WARNING]
> Bootstrap maintenance is separate from AIO reconciliation. Coordinate stored script formats and retrieval loaders before rebuilding VMs, adding nodes, or rerunning setup. See [Bootstrap Maintenance](../../src/100-edge/100-cncf-cluster/README.md#bootstrap-maintenance) for the lifecycle exclusions and the Arc-machine/SSH boundary.

## Reconcile with Bicep

Bicep is stateless — there is no per-deployment record of previously applied versions to reconcile. After `az iot ops upgrade` no further ARM operations are required to "import" the new state. Subsequent Bicep deployments are idempotent against whatever exists in Azure.

1. Run the AIO upgrade as shown above.

2. Re-run edge-ai with the latest AIO version pins and any updated components.

   - Pull the latest edge-ai changes (which may bump the defaults in [109-arc-extensions/bicep/types.bicep](../../src/100-edge/109-arc-extensions/bicep/types.bicep) and [110-iot-ops/bicep/types.bicep](../../src/100-edge/110-iot-ops/bicep/types.bicep)).
   - Re-deploy your blueprint with `az deployment group create` (or your existing pipeline) using the same parameters.

   If the parameter values are equal to or newer than what `az iot ops upgrade` installed, ARM applies the new versions. Otherwise the deployment is a no-op for the AIO extensions.

> **Pinned releases**: If your team pins to a specific edge-ai release tag, ensure the version parameters passed to the blueprint match or exceed what `az iot ops upgrade` installed. If they are lower, the next deployment will attempt to downgrade the extensions. Override the version parameters explicitly or upgrade to an edge-ai release that includes the newer defaults.
>
> Because Bicep / ARM compares declared properties to live resource state, you do not need a refresh, import, or state-edit step. The next deployment is the reconciliation.

## Troubleshooting

- Terraform still shows version differences after `-refresh-only`: compare installed versions with effective configuration, including overrides. Older pins can request downgrades and newer pins can request further upgrades. Align the configuration and review the complete plan before any normal apply.
- **`az iot ops upgrade` reports no updates**: the cluster is already on the latest stable channel for all three components; nothing to reconcile.
- **Permission errors during refresh**: ensure your principal has read access on the connected cluster, the cluster extensions, and the AIO instance resource group.

## References

- [Supported versions — Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-upgrade?tabs=portal#supported-versions)
- [Upgrade Azure IoT Operations — Official guide](https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-upgrade)
- [Terraform refresh-only mode](https://developer.hashicorp.com/terraform/cli/commands/plan#planning-modes)
- [Azure Container Storage enabled by Azure Arc FAQ](https://learn.microsoft.com/azure/azure-arc/container-storage/faq)
- [Update an Arc Kubernetes extension](https://learn.microsoft.com/cli/azure/k8s-extension#az-k8s-extension-update)
- [Terraform state removal](https://developer.hashicorp.com/terraform/cli/commands/state/rm)
- [AzAPI resource import](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#import)
