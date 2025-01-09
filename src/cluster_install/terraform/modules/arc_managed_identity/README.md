<!-- BEGIN_TF_DOCS -->
# Create Service Principal for Azure Arc

Create SP with minimal permissions to onboard the VM to Azure Arc
Meant to make it easier to get the Virtual edge device up and running and not for production use

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_role_assignment.connected_machine_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.arc_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### location

Description: Location for all resources in this module

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
<!-- END_TF_DOCS -->