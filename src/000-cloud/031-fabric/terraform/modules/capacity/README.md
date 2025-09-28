<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| azurerm | >= 4.23.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.23.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_fabric_capacity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/fabric_capacity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| name | The name of the Fabric capacity. | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| admin\_members | List of AAD object IDs for Fabric capacity administrators. | `list(string)` | `[]` | no |
| sku | SKU name for the resource | `string` | `"F2"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| capacity | The Fabric capacity. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
