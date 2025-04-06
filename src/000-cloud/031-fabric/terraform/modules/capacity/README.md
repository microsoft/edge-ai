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
| location | The Azure region in which to create the Fabric capacity | `string` | n/a | yes |
| name | The name of the Fabric capacity | `string` | n/a | yes |
| resource\_group\_name | The name of the resource group in which to create the Fabric capacity | `string` | n/a | yes |
| admin\_members | List of AAD object IDs for Fabric capacity administrators | `list(string)` | `[]` | no |
| capacity\_id | The ID of an existing Fabric capacity to use (required when create\_capacity=false) | `string` | `null` | no |
| create\_capacity | Boolean flag to determine whether to create a new Fabric capacity or use an existing one | `bool` | `true` | no |
| sku | The SKU name for the Fabric capacity | `string` | `"F2"` | no |
| tags | Tags to apply to the Fabric capacity | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| capacity\_id | The ID of the Fabric capacity |
| capacity\_name | The name of the Fabric capacity |
| capacity\_sku | The SKU of the Fabric capacity |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
