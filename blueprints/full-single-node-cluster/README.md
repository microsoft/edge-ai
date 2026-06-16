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

If you previously deployed `full-single-node-cluster` with Terraform, point your existing state at the unified blueprint. Only one module address changed: `module.cloud_vm_host` is now count-gated (`count = local.should_use_arc_machines ? 0 : 1`, which evaluates to `1` by default), so its instance address became `module.cloud_vm_host[0]`.

Run the following from the unified blueprint's `terraform/` directory after `terraform init`:

```sh
terraform state mv 'module.cloud_vm_host' 'module.cloud_vm_host[0]'
terraform plan   # expect: No changes
```

The module-level move relocates the entire `cloud_vm_host` subtree (virtual machine, SSH key, generated password, VM extension, and role assignments), so no per-child moves are required.

The new `data.azurerm_arc_machine.arc_machines` and `terraform_data.defer_arc_machine_prefix` resources are count-0 when `should_use_arc_machines = false` (the single-node default), so they create no state entries and need no moves.

Following this guide against an existing single-node state yields a `terraform plan` with zero resources created and zero resources destroyed.

## Variable Changes

No existing variable default changed in a way that alters deployed infrastructure. `host_machine_count` is new and defaults to `1`, which reproduces the single node. The unified blueprint adds 17 new variables, all with single-node-safe defaults (`should_use_arc_machines = false`, `arc_machine_count = 1`). You do not need to re-pin any variable to preserve your current topology. Setting `host_machine_count > 1` or `should_use_arc_machines = true` are opt-in changes that intentionally alter infrastructure.

## Bicep Migration

No Bicep parameters were removed or renamed. Adjusting your `.bicepparam` for the unified blueprint:

* `adminPassword` is now nullable (`string?`) but remains required for the VM deployment path, so keep supplying it.
* Nine new parameters are available: `arcMachineCount`, `arcMachineName`, `arcMachineNamePrefix`, `arcMachineResourceGroupName`, `clusterServerHostMachineUsername`, `clusterServerIp`, `hostMachineCount`, `serverToken`, and `shouldUseArcMachines`.
* `@minValue(1)` was added to `hostMachineCount` and `arcMachineCount`.
* `serverToken` is only needed when `hostMachineCount > 1`.

All new parameters default to single-node VM behavior, so a migrating Bicep user reproduces the prior topology without adopting any of them.

## Output Set

The unified Terraform blueprint trimmed roughly 10 outputs that existed in the previous single-node blueprint. If your automation consumed any of those outputs, review the unified blueprint's [outputs.tf](../full-multi-node-cluster/terraform/outputs.tf) and update references to the current output names before migrating.

## Related

* [Blueprints overview](../README.md)
* [Full Multi-node Cluster Blueprint](../full-multi-node-cluster/README.md)
