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
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| key\_vault\_admin\_principal\_id | The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault. | `string` | n/a | yes |
| key\_vault\_name | The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource\_prefix}-{environment}-{instance}' | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| private\_endpoint\_subnet\_id | The ID of the subnet where the private endpoint will be created | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_add\_key\_vault\_role\_assignment | Whether to add role assignment to the Key Vault | `bool` | n/a | yes |
| should\_create\_private\_endpoint | Whether to create a private endpoint for the Key Vault | `bool` | n/a | yes |
| should\_enable\_public\_network\_access | Whether to enable public network access for the Key Vault | `bool` | n/a | yes |
| virtual\_network\_id | The ID of the virtual network to link to the private DNS zone | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |

## Outputs

| Name | Description |
|------|-------------|
| key\_vault | n/a |
| private\_dns\_zone | The private DNS zone for Key Vault. |
| private\_endpoint | The private endpoint resource for Key Vault. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
