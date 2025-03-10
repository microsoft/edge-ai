<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# User Assigned Managed Identities for Azure IoT Operations

Create User Assigned Managed Identities for Azure IoT Operations and assign roles to them

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
| [azurerm_role_assignment.uami_key_vault_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.uami_key_vault_secrets_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.user_managed_identity_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.user_managed_identity_secret_sync](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | n/a | yes |
| key\_vault\_id | ID of the Key Vault to use by the Secret Sync Extension | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | The name for the resource group. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| aio\_uami\_name | n/a |
| aio\_user\_assigned\_identity | n/a |
| sse\_uami\_name | n/a |
| sse\_user\_assigned\_identity | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
