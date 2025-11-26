<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Machine Learning Workspace Module

This module creates an Azure ML workspace with required dependencies
and optional private endpoint configuration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_machine_learning_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_workspace) | resource |
| [azurerm_private_dns_zone.azureml_zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.azureml_vnet_links](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.azureml_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.ml_workload_acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.ml_workload_blob_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.ml_workload_file_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.ml_workload_key_vault_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.ml_workload_workspace_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.storage_blob_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.workspace_acr_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.workspace_appinsights_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.workspace_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.workspace_keyvault_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.workspace_storage_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application\_insights\_id | Resource ID of the Application Insights instance. | `string` | n/a | yes |
| container\_registry\_id | Resource ID of the Container Registry (optional). | `string` | n/a | yes |
| current\_user\_object\_id | Object ID of the current Azure AD user (deferred and passed from component). | `string` | n/a | yes |
| description | Description of the workspace. | `string` | n/a | yes |
| environment | The environment for the deployment. | `string` | n/a | yes |
| friendly\_name | Friendly display name for the workspace. | `string` | n/a | yes |
| instance | Instance identifier for the deployment. | `string` | n/a | yes |
| key\_vault\_id | Resource ID of the Key Vault instance. | `string` | n/a | yes |
| location | Azure region where the workspace will be created. | `string` | n/a | yes |
| ml\_workload\_identity | AzureML workload managed identity object containing id and principal\_id. | ```object({ id = string principal_id = string })``` | n/a | yes |
| name | Name of the Azure Machine Learning workspace. | `string` | n/a | yes |
| public\_network\_access\_enabled | Whether to enable public network access to the workspace. | `bool` | n/a | yes |
| resource\_group\_name | Name of the resource group containing the workspace. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resource names. | `string` | n/a | yes |
| should\_assign\_current\_user\_workspace\_roles | Whether to assign the current user Contributor role on the workspace (passed from component). | `bool` | n/a | yes |
| should\_assign\_workspace\_managed\_identity\_roles | Whether to assign the workspace system-assigned managed identity roles to access dependent Azure services (Storage, ACR, Key Vault, Application Insights). | `bool` | n/a | yes |
| storage\_account\_id | Resource ID of the Storage Account for ML artifacts. | `string` | n/a | yes |
| private\_endpoint\_subnet\_id | The ID of the subnet where the private endpoint will be created | `string` | `null` | no |
| should\_assign\_ml\_workload\_identity\_roles | Whether to assign dependent resource roles to the ML workload managed identity | `bool` | `false` | no |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the Azure ML workspace | `bool` | `false` | no |
| virtual\_network\_id | The ID of the virtual network to link to the private DNS zone | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| principal\_id | The Principal ID of the System Assigned Managed Service Identity. |
| private\_dns\_zones | Map of private DNS zones created for AzureML services |
| private\_endpoint | The private endpoint resource for Azure ML workspace. |
| workspace | Azure Machine Learning workspace object. |
| workspace\_discovery\_url | AzureML workspace discovery URL |
| workspace\_id | The immutable resource ID of the workspace. |
| workspace\_name | The name of the workspace. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
