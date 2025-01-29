<!-- BEGIN_TF_DOCS -->
# User Assigned Managed Identities for Azure IoT Operations

Create User Assigned Managed Identities for Azure IoT Operations and assign roles to them

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_role_assignment.uami_key_vault_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.uami_key_vault_secrets_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.user_managed_identity_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_user_assigned_identity.user_managed_identity_secret_sync](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### key\_vault\_id

Description: ID of the Key Vault to use by the Secret Sync Extension

Type: `string`

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

### aio\_uami\_name

Description: n/a

### sse\_uami\_name

Description: n/a
<!-- END_TF_DOCS -->
