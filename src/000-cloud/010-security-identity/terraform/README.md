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
| msgraph | >= 0.2.0 |

## Providers

| Name | Version |
|------|---------|
| msgraph | >= 0.2.0 |

## Resources

| Name | Type |
|------|------|
| [msgraph_resource_action.current_user](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_action) | resource |

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
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| key\_vault\_admin\_principal\_id | The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault. | `string` | `null` | no |
| key\_vault\_name | The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| key\_vault\_private\_endpoint\_subnet\_id | The ID of the subnet where the Key Vault private endpoint will be created. Required if should\_create\_key\_vault\_private\_endpoint is true. | `string` | `null` | no |
| key\_vault\_virtual\_network\_id | The ID of the virtual network to link to the Key Vault private DNS zone. Required if should\_create\_key\_vault\_private\_endpoint is true. | `string` | `null` | no |
| onboard\_identity\_type | Identity type to use for onboarding the cluster to Azure Arc.  Allowed values:  - id - sp - skip | `string` | `"id"` | no |
| should\_create\_aio\_identity | Whether to create a user-assigned identity for Azure IoT Operations. | `bool` | `true` | no |
| should\_create\_aks\_identity | Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones. | `bool` | `false` | no |
| should\_create\_identities | Whether to create the identities used for Arc Onboarding, Secret Sync, and AIO. | `bool` | `true` | no |
| should\_create\_key\_vault | Whether to create the Key Vault. | `bool` | `true` | no |
| should\_create\_key\_vault\_private\_endpoint | Whether to create a private endpoint for the Key Vault. | `bool` | `false` | no |
| should\_create\_ml\_workload\_identity | Whether to create a user-assigned identity for AzureML workloads. | `bool` | `false` | no |
| should\_create\_secret\_sync\_identity | Whether to create a user-assigned identity for Secret Sync Extension. | `bool` | `true` | no |
| should\_enable\_public\_network\_access | Whether to enable public network access for the Key Vault | `bool` | `true` | no |
| should\_use\_current\_user\_key\_vault\_admin | Whether to give the current user the Key Vault Secrets Officer Role. | `string` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_identity | n/a |
| aks\_identity | The AKS user-assigned identity for custom private DNS zone scenarios. |
| arc\_onboarding\_identity | n/a |
| arc\_onboarding\_sp | n/a |
| key\_vault | n/a |
| key\_vault\_private\_dns\_zone | The private DNS zone for Key Vault. |
| key\_vault\_private\_endpoint | The private endpoint for Key Vault. |
| ml\_workload\_identity | The AzureML workload user-assigned identity. |
| secret\_sync\_identity | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
