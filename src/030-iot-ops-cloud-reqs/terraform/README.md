<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Cloud Requirements

Sets up required cloud resources for Azure IoT Operations installation
including: Schema Registry, Azure Key Vault, and Roles and Permissions for
access to resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.1.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_resource_group.aio_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| schema\_registry | ./modules/schema-registry | n/a |
| sse\_key\_vault | ./modules/sse-key-vault | n/a |
| uami | ./modules/uami | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| existing\_key\_vault\_name | Name of the Azure Key Vault to use by Secret Sync Extension. If not provided, will create new key vault. Will fail if provided key vault does not exist in provided resource group. | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| resource\_group\_name | The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_uami\_name | n/a |
| schema\_registry\_id | n/a |
| sse\_key\_vault\_name | n/a |
| sse\_uami\_name | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
