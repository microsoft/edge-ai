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
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| identity | ./modules/identity | n/a |
| key\_vault | ./modules/key-vault | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_resource\_group | n/a | ```object({ id = string name = string location = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| key\_vault\_admin\_principal\_id | The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault. | `string` | `null` | no |
| key\_vault\_name | The resource name for the new Key Vault. (Otherwise, 'kv-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
| onboard\_identity\_type | Identity type to use for onboarding the cluster to Azure Arc.  Allowed values:  - id - sp - skip | `string` | `"id"` | no |
| should\_create\_identities | Whether to create the identities used for Arc Onboarding, Secret Sync, and AIO. | `bool` | `true` | no |
| should\_create\_key\_vault | Whether to create the Key Vault. | `bool` | `true` | no |
| should\_use\_current\_user\_key\_vault\_admin | Whether to give the current user the Key Vault Secrets Officer Role. | `string` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_identity | n/a |
| arc\_onboarding\_identity | n/a |
| arc\_onboarding\_sp | n/a |
| key\_vault | n/a |
| secret\_sync\_identity | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
