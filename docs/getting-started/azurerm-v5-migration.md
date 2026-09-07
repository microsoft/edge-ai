---
title: Migrate Terraform deployments to AzureRM v5
description: State-aware procedure for upgrading existing edge-ai Terraform blueprint deployments from AzureRM v4 to v5
author: Edge AI Team
ms.date: 2026-09-01
ms.topic: how-to
estimated_reading_time: 8
keywords:
  - terraform
  - azurerm
  - migration
  - state
  - azure resource providers
---

## Migrate Terraform deployments to AzureRM v5

AzureRM v5 contains breaking provider and resource-schema changes. Use this
procedure when upgrading an existing edge-ai Terraform blueprint deployment
from AzureRM v4. New deployments can use the current configuration directly.

> [!WARNING]
> Do not apply a plan that contains unexplained resource replacement or
> destruction. Stop and investigate before changing existing infrastructure.

## Prerequisites

* Use the same Terraform backend, workspace, variable files, and Azure
  subscription as the existing deployment.
* Install the Terraform version required by the selected blueprint.
* Sign in to Azure CLI with permission to read the deployment and register
  resource providers at subscription scope.
* Pull the edge-ai revision that contains the AzureRM v5 migration.
* Confirm no other operator or pipeline can modify the same Terraform state
  during the upgrade.

## Prepare the subscription

AzureRM v5 roots in this repository set
`resource_provider_registrations = "none"`. Register the canonical provider
set before initialization or planning:

```bash
cd src/azure-resource-providers
./register-azure-providers.sh aio-azure-resource-providers.txt
cd ../..
```

The script is idempotent and must run once for each target subscription. For
required permissions and PowerShell usage, see
[Register Azure Resource Providers](../../src/azure-resource-providers/README.md).

## Back up Terraform state

Change to the Terraform directory for the blueprint that owns the deployment,
then initialize the Azure subscription environment:

```bash
cd blueprints/<blueprint-name>/terraform
source ../../../scripts/az-sub-init.sh
```

Create a state backup outside the repository. Terraform state can contain
sensitive values, so restrict access to the file and retain it according to
your organization's recovery policy.

```bash
umask 077
backup_file="${HOME}/azurerm-v5-state-$(date -u +%Y%m%dT%H%M%SZ).json"
terraform state pull > "${backup_file}"
test -s "${backup_file}"
```

For remote backends, retain the backend's native version or snapshot as an
additional recovery point.

## Upgrade and create a saved plan

Upgrade provider selections within the repository's supported v5 range:

```bash
terraform init -upgrade
terraform providers
```

Confirm the selected `hashicorp/azurerm` version satisfies
`>= 5.3.0, < 6.0.0`. This repository does not commit Terraform lock files, so
keep the locally generated lock file unchanged between plan and apply.

Create a saved plan with the same inputs used by the existing deployment:

```bash
terraform plan -out=azurerm-v5.tfplan -var-file=terraform.tfvars
terraform show azurerm-v5.tfplan
```

If the deployment uses additional variable files or CLI variables, include
them in the plan command. Do not substitute example inputs for the deployed
configuration.

## Review expected changes

The migration updates provider schemas while preserving the intended Azure
resources:

* Log Analytics public ingestion remains enabled. Query access remains enabled
  unless the deployment enables the broader private-endpoint configuration.
* Private DNS links and A records use existing private DNS zone resource IDs.
* AKS uses manual node provisioning, preserving the existing Terraform-managed
  default and additional node pools.
* Key Vault RBAC authorization remains enabled.
* Azure Machine Learning registry DNS records continue to use the workspace's
  shared private DNS zone.

Provider-version and in-place schema updates can appear in the plan. These
changes must not create a new private DNS zone, replace an AKS cluster, disable
Key Vault RBAC, or resize a virtual machine unexpectedly.

For the full-multi-node blueprint, set `vm_sku_size` to the SKU already stored
in state before planning. This prevents the component default from introducing
an unrelated VM resize. Inspect the current value when needed:

```bash
terraform state show 'module.cloud_vm_host[0].module.virtual_machine[0].azurerm_linux_virtual_machine.vm'
```

Resource addresses can vary with deployment inputs. Use `terraform state list`
to find the applicable VM address.

## Apply the reviewed plan

Apply only the saved plan that was reviewed and approved through your normal
change-management process:

```bash
terraform apply azurerm-v5.tfplan
```

Do not run an unsaved `terraform apply` for this migration. A new plan can
select different provider versions or observe changed remote state.

After apply, create a fresh plan with the same variables. The expected result
is no changes:

```bash
terraform plan -var-file=terraform.tfvars
```

## Roll back safely

If initialization or planning fails, or the plan contains unexplained
replacement or destruction, stop before apply. Restore the previous source
revision and provider selection, then initialize and plan again against the
unchanged state.

Do not downgrade an applied AzureRM v5 state to v4. If a confirmed regression
exists within the supported v5 range, temporarily pin the last validated v5
release with an exact constraint such as `= 5.3.0`, then repeat every
validation and plan-review gate. Remove the pin only after a corrected minimum
version passes the same gates.

Restoring a state backup after apply can disconnect Terraform state from live
Azure resources. Use `terraform state push` only as part of an approved
recovery procedure after verifying that the backup and infrastructure describe
the same point in time.

## Troubleshooting

### Resource provider is not registered

Run the canonical registration script against the target subscription, wait
for required namespaces to reach `Registered`, and rerun the failed command.
Do not enable automatic provider registration to bypass the prerequisite.

### Initialization selects an unexpected provider version

Remove only the ignored local `.terraform` directory and lock file after
preserving any required local evidence, then rerun `terraform init -upgrade`.
Confirm the configured constraint is `>= 5.3.0, < 6.0.0`.

### The plan proposes replacement or destruction

Do not apply. Confirm the backend, workspace, subscription, variable files,
and VM SKU match the existing deployment. Review private DNS zone IDs and AKS
settings for input drift. Escalate any replacement that remains unexplained.

### The post-apply plan is not empty

Compare the residual plan with the reviewed saved plan and the state backup.
Treat new replacement, destruction, access-policy, DNS, AKS, or VM-size changes
as migration failures until their cause is understood.
