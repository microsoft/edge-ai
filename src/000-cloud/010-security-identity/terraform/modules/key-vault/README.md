<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Key Vault for Secret Sync Extension

Create or use and existing a Key Vault for Secret Sync Extension

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| key\_vault\_admin\_principal\_id | The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault. | `string` | n/a | yes |
| key\_vault\_name | The name of the Key Vault for Secret Sync Extension. (Otherwise, 'kv-{var.resource\_prefix}-{var.environment}-{var.instance}' | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |

## Outputs

| Name | Description |
|------|-------------|
| key\_vault | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
