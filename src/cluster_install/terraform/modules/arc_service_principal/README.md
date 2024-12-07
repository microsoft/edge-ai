<!-- BEGIN_TF_DOCS -->
# Create Service Principal for Azure Arc

Create SP with minimal permissions to onboard the VM to Azure Arc
Meant to make it easier to get the Virtual edge device up and running and not for production use

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
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### resource\_group\_id

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Outputs

The following outputs are exported:

### sp\_client\_id

Description: n/a

### sp\_client\_secret

Description: n/a
<!-- END_TF_DOCS -->