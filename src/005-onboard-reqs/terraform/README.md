<!-- BEGIN_TF_DOCS -->
# Onboard Infrastructure Requirements

Creates the required resources needed for an edge IaC deployment.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azuread (>= 3.0.2)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azurerm (>= 4.8.0)

- terraform

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

## Modules

The following Modules are called:

### onboard\_identity

Source: ./modules/onboard-identity

Version:

## Required Inputs

The following input variables are required:

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

### onboard\_identity\_type

Description: Identity type to use for onboarding the cluster to Azure Arc.

Allowed values:

- uami
- sp

Type: `string`

Default: `"uami"`

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`

### should\_create\_onboard\_identity

Description: Should create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc.

Type: `bool`

Default: `true`

### should\_create\_resource\_group

Description: Should create and manage a new Resource Group.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### arc\_onboarding\_sp\_client\_id

Description: The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions.

### arc\_onboarding\_sp\_client\_secret

Description: The Service Principal Secret used for automation.

```sh
terraform output -json | jq -r '.arc_onboard_sp_client_secret.value'
```

### arc\_onboarding\_user\_managed\_identity\_id

Description: The User Assigned Managed Identity ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions.

### arc\_onboarding\_user\_managed\_identity\_name

Description: The User Assigned Managed Identity name with 'Kubernetes Cluster - Azure Arc Onboarding' permissions.

### rg\_id

Description: New or existing Resource Group ID.

### rg\_name

Description: New or existing Resource Group name.
<!-- END_TF_DOCS -->
