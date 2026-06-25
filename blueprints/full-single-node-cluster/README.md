---
title: Full Single-node Cluster Blueprint (Consolidated)
description: Migration pointer for the retired full-single-node-cluster blueprint, now consolidated into full-multi-node-cluster with a verified Terraform state move and Bicep parameter guide
author: Edge AI Team
ms.date: 2026-06-16
ms.topic: how-to
keywords:
  - azure iot operations
  - single node cluster
  - migration
  - terraform state mv
  - bicep
  - edge computing
---

## Overview

This blueprint has been consolidated into [full-multi-node-cluster](../full-multi-node-cluster/). A single parameterized blueprint now covers both single-node and multi-node deployments, so the standalone `full-single-node-cluster` blueprint is retained only as this migration pointer.

Single-node is the default configuration of the unified blueprint. With `host_machine_count = 1` and `should_use_arc_machines = false`, the unified blueprint reproduces the exact topology that this blueprint previously deployed.

Use the unified blueprint going forward:

* Terraform: [full-multi-node-cluster/terraform](../full-multi-node-cluster/terraform/)
* Bicep: [full-multi-node-cluster/bicep](../full-multi-node-cluster/bicep/)

## Why It Moved

Maintaining separate single-node and multi-node blueprints duplicated nearly identical orchestration. The unified blueprint parameterizes node count and Arc-machine targeting, which keeps one source of truth and lets you scale from a single VM-backed node to a multi-node or Arc-enabled cluster by changing inputs rather than switching blueprints.

## Terraform State Migration

If you previously deployed `full-single-node-cluster` with Terraform, migrate your existing state to the unified blueprint. Only one module address changed: `module.cloud_vm_host` is now count-gated (`count = local.should_use_arc_machines ? 0 : 1`, which evaluates to `1` by default), so its instance address became `module.cloud_vm_host[0]`.

For a **local-state** deployment, back up first, seed the unified blueprint directory with your variables, a working copy of the state, **and the generated SSH key directory**, then perform the single documented move:

```sh
# From the repository root

# 1. Back up your live state outside the repo
cp blueprints/full-single-node-cluster/terraform/terraform.tfstate \
   ~/sn-state-backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. Seed the unified blueprint with your tfvars and a working copy of the state
cp blueprints/full-single-node-cluster/terraform/terraform.tfvars \
   blueprints/full-multi-node-cluster/terraform/terraform.tfvars
cp blueprints/full-single-node-cluster/terraform/terraform.tfstate \
   blueprints/full-multi-node-cluster/terraform/terraform.tfstate

# 3. Copy the generated SSH key directory (see "Migration no-op requirements").
#    cloud_vm_host writes local_sensitive_file.private_key to ../.ssh relative to the
#    terraform directory. If the key file is absent in the new working directory,
#    Terraform treats it as a deleted resource and that single change cascades into a
#    full IoT Operations and dataflow replacement.
cp -rp blueprints/full-single-node-cluster/.ssh \
   blueprints/full-multi-node-cluster/.ssh

# 4. Set the subscription environment, then init and move
source scripts/az-sub-init.sh
cd blueprints/full-multi-node-cluster/terraform
terraform init
terraform state mv 'module.cloud_vm_host' 'module.cloud_vm_host[0]'

# 5. Plan, preserving your existing resource-group blueprint tag (see "Migration no-op
#    requirements"). Omitting this flag flips the tag and cascades into a full replacement.
terraform plan -var 'tags={"blueprint":"full-single-node-cluster"}'   # expect: 0 to add, 0 to destroy
```

For a **remote backend**, point the unified blueprint at the same backend (reuse your `backend` block / `-backend-config`), run `terraform init`, then run only the SSH key copy, `terraform state mv`, and `terraform plan` steps above.

The module-level move relocates the entire `cloud_vm_host` subtree (virtual machine, SSH key, generated password, VM extension, and role assignments), so no per-child moves are required.

The new `data.azurerm_arc_machine.arc_machines` and `terraform_data.defer_arc_machine_prefix` resources are count-0 when `should_use_arc_machines = false` (the single-node default), so they create no state entries and need no moves.

### Migration no-op requirements

A clean migration produces a `terraform plan` with `0 to add, 0 to destroy`. Two non-obvious requirements protect that outcome, and skipping either one cascades into a full replacement of the IoT Operations instance, custom location, MQTT broker, and every dataflow graph:

* **Copy the `.ssh` directory.** `module.cloud_vm_host` writes its generated private key to `blueprints/full-multi-node-cluster/.ssh/` via `local_sensitive_file`. A missing key file is a pending change on `cloud_vm_host`. Because the edge modules declare `depends_on = [module.cloud_vm_host]`, that pending change defers the cluster identity data sources to apply time, which forces the downstream Arc and IoT Operations resources to be replaced.
* **Preserve the `blueprint` resource-group tag.** The unified blueprint tags resources `blueprint = full-multi-cluster`, but your state carries `blueprint = full-single-node-cluster`. The tag is overridable through `var.tags`, so pass `-var 'tags={"blueprint":"full-single-node-cluster"}'`. A bare tag change re-reads the current-user identity data sources at apply, making the bootstrap script and OIDC issuer "known after apply" and triggering the same cascade.

After both safeguards are in place, the migration plan reports `0 to add, 0 to destroy` with only benign in-place updates: an observability dashboard drift refresh and a cosmetic `headers: [] -> null` normalization on the dataflow graphs and endpoints. Once your topology is migrated, you can drop the tag override to adopt the `full-multi-cluster` tag in a later apply.

## Variable Changes

No existing variable default changed in a way that alters deployed infrastructure. `host_machine_count` is new and defaults to `1`, which reproduces the single node. The unified blueprint adds 17 new variables, all with single-node-safe defaults (`should_use_arc_machines = false`, `arc_machine_count = 1`). You do not need to re-pin any variable to preserve your current topology. Setting `host_machine_count > 1` or `should_use_arc_machines = true` are opt-in changes that intentionally alter infrastructure.

## Bicep Migration

No Bicep parameters were removed or renamed. Adjusting your `.bicepparam` for the unified blueprint:

* `adminPassword` is now nullable (`string?`) but remains required for the VM deployment path, so keep supplying it.
* Nine new cluster parameters are available: `arcMachineCount`, `arcMachineName`, `arcMachineNamePrefix`, `arcMachineResourceGroupName`, `clusterServerHostMachineUsername`, `clusterServerIp`, `hostMachineCount`, `serverToken`, and `shouldUseArcMachines`.
* Nine new notification parameters are available for the optional 045-notification Logic App: `shouldDeployNotification`, `alertEventHubName`, `notificationEventSchema`, `notificationMessageTemplate`, `closureMessageTemplate`, `notificationPartitionKeyField`, `teamsRecipientId`, `teamsGroupId`, and `teamsPostLocation`.
* `@minValue(1)` was added to `hostMachineCount` and `arcMachineCount`.
* `serverToken` is only needed when `hostMachineCount > 1`.

All new parameters default to single-node VM behavior, so a migrating Bicep user reproduces the prior topology without adopting any of them.

## Output Set

The unified Terraform blueprint preserves the full single-node output set, including `kubernetes`, `function_app`,
`azureml_workspace`, `azureml_compute_cluster`, `azureml_extension`, `azureml_inference_cluster`, `vpn_gateway`,
`vpn_gateway_public_ip`, `vpn_client_connection_info`, and `private_resolver_dns_ip`.
These are emitted with `try(..., null)`, so they return `null` when the corresponding module is not deployed —
see the unified blueprint's [outputs.tf](../full-multi-node-cluster/terraform/outputs.tf).
For the impact on existing multi-node deployments,
see [Migration Notes for Existing Multi-node Deployments](../full-multi-node-cluster/README.md#migration-notes-for-existing-multi-node-deployments).

## Related

* [Blueprints overview](../README.md)
* [Full Multi-node Cluster Blueprint](../full-multi-node-cluster/README.md)
