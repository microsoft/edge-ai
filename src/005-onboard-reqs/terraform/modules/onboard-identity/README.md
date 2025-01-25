<!-- BEGIN_TF_DOCS -->
# Create Managed identity or Service Principal for Azure Arc cluster onboarding

Create UAMI/SP with minimal permissions to onboard the VM to Azure Arc.
Used with a hands-off deployment that will embed UAMI/SP

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azuread

- azurerm

## Resources

The following resources are used by this module:

- [azuread_application.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) (resource)
- [azuread_application_password.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) (resource)
- [azuread_service_principal.aio_edge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) (resource)
- [azurerm_role_assignment.connected_machine_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.arc_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### location

Description: Location for all resources in this module

Type: `string`

### onboard\_identity\_type

Description: Identity type to use for onboarding the cluster to Azure Arc.

- `uami`
- `sp`

Type: `string`

### resource\_group\_id

Description: Resource group id to scope the role assignment to

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Outputs

The following outputs are exported:

### arc\_onboarding\_user\_managed\_identity\_id

Description: n/a

### arc\_onboarding\_user\_managed\_identity\_name

Description: n/a

### sp\_client\_id

Description: n/a

### sp\_client\_secret

Description: n/a
<!-- END_TF_DOCS -->
