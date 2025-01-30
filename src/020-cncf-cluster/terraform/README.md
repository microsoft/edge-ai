<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# CNCF Cluster

Sets up and deploys a script to a VM host that will setup the cluster,
Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
install extensions for cluster connect and custom locations.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_virtual_machine_extension.linux_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azuread_service_principal.custom_locations](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.aio_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_machine.aio_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_machine) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| add\_current\_entra\_user\_cluster\_admin | Adds the current user as cluster-admin cluster role binding | `bool` | `true` | no |
| arc\_auto\_upgrade | Enable or disable auto-upgrades of Arc agents. (Meant for dev environments, avoid auto-upgrade in prod). | `bool` | `true` | no |
| arc\_onboarding\_sp\_client\_id | The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. | `string` | `null` | no |
| arc\_onboarding\_sp\_client\_secret | The Service Principal Client Secret use for automation. | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| linux\_virtual\_machine\_name | The name for the Linux Virtual Machine resource. (Otherwise, '{var.resource\_prefix}-aio-edge-vm') | `string` | `null` | no |
| resource\_group\_name | The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
| vm\_username | Name for the VM user to create on the target VM. If left empty, a random name will be generated | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| azure\_arc\_proxy\_command | n/a |
| connected\_cluster\_name | n/a |
| connected\_cluster\_resource\_group\_name | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
