<!-- BEGIN_TF_DOCS -->
# Azure Key Vault

Deploys a Key Vault account to be used for further configuring Azure IoT Operations deployments

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_key_vault.aio_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_role_assignment.umi_key_vault_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.umi_key_vault_secrets_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.user_managed_identity_secret_sync](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### location

Description: Location for all resources in this module

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Outputs

The following outputs are exported:

### name

Description: n/a

### sse\_user\_managed\_identity\_name

Description: n/a
<!-- END_TF_DOCS -->