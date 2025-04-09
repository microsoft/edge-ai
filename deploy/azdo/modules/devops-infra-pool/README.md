<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Managed DevOps Pool for Accelerator

Create a Dev Center and Project to host a Managed DevOps Pool for Accelerator

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | n/a |
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.managed_devops_pool](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_dev_center.dev_center](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center) | resource |
| [azurerm_dev_center_project.dev_center_project](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_project) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| resource\_group | Resource group for all resources in this module. | ```object({ id = string name = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| snet\_pool | Subnet for the Azure DevOps agent pool. | ```object({ id = string })``` | n/a | yes |
| azdo\_org\_name | Azure DevOps organization name. | `string` | `null` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
