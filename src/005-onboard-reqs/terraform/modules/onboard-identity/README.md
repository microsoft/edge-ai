<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Create Managed identity or Service Principal for Azure Arc cluster onboarding

Create UAMI/SP with minimal permissions to onboard the VM to Azure Arc.
Used with a hands-off deployment that will embed UAMI/SP

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
| [azurerm_role_assignment.connected_machine_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.arc_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| onboard\_identity\_type | Identity type to use for onboarding the cluster to Azure Arc.  Allowed values:  - uami - sp | `string` | n/a | yes |
| resource\_group\_id | The ID for the Resource Group for the resources. | `string` | n/a | yes |
| resource\_group\_name | The name for the resource group. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| arc\_onboarding\_user\_assigned\_identity | n/a |
| arc\_onboarding\_user\_managed\_identity\_id | n/a |
| arc\_onboarding\_user\_managed\_identity\_name | n/a |
| sp\_client\_id | n/a |
| sp\_client\_secret | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
