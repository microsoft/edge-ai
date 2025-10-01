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
| azuread | n/a |
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azuread_application.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_user_assigned_identity.aks_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.arc_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.ml_workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.user_managed_identity_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.user_managed_identity_secret_sync](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| onboard\_identity\_type | Identity type to use for onboarding the cluster to Azure Arc.  Allowed values:  - id - sp - skip | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_create\_aio\_identity | Whether to create a user-assigned identity for Azure IoT Operations. | `bool` | n/a | yes |
| should\_create\_aks\_identity | Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones. | `bool` | n/a | yes |
| should\_create\_ml\_workload\_identity | Whether to create a user-assigned identity for AzureML workloads. | `bool` | n/a | yes |
| should\_create\_secret\_sync\_identity | Whether to create a user-assigned identity for Secret Sync Extension. | `bool` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_identity | n/a |
| aks\_identity | The AKS user-assigned identity for custom private DNS zone scenarios. |
| arc\_onboarding\_identity | n/a |
| arc\_onboarding\_sp | n/a |
| ml\_workload\_identity | The AzureML workload user-assigned identity. |
| secret\_sync\_identity | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
