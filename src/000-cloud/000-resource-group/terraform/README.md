<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Onboard Infrastructure Requirements

Creates the required resources needed for an edge IaC deployment or uses an existing resource group.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| resource\_group\_name | Name of the resource group | `string` | `null` | no |
| tags | Tags to apply to all resources | `map(string)` | `null` | no |
| use\_existing\_resource\_group | Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource\_group | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
