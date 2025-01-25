<!-- BEGIN_TF_DOCS -->
# CNCF Cluster

Sets up and deploys a script to a VM host that will setup the cluster,
Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
install extensions for cluster connect and custom locations.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azuread (>= 3.0.2)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azuread (>= 3.0.2)

- azurerm (>= 4.8.0)

- terraform

## Resources

The following resources are used by this module:

- [azurerm_virtual_machine_extension.linux_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) (resource)
- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [azuread_service_principal.custom_locations](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [azurerm_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_machine) (data source)

## Required Inputs

The following input variables are required:

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### add\_current\_entra\_user\_cluster\_admin

Description: Adds the current user as cluster-admin cluster role binding

Type: `bool`

Default: `true`

### arc\_auto\_upgrade

Description: Enable or disable auto-upgrades of Arc agents. (Meant for dev environments, avoid auto-upgrade in prod).

Type: `bool`

Default: `true`

### arc\_onboarding\_sp\_client\_id

Description: The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions.

Type: `string`

Default: `null`

### arc\_onboarding\_sp\_client\_secret

Description: The Service Principal Client Secret use for automation.

Type: `string`

Default: `null`

### custom\_locations\_oid

Description: The object id of the Custom Locations Entra ID application for your tenant.  
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

```sh
az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
```

Type: `string`

Default: `null`

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

### linux\_virtual\_machine\_name

Description: The name for the Linux Virtual Machine resource. (Otherwise, '{var.resource\_prefix}-aio-edge-vm')

Type: `string`

Default: `null`

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`

### vm\_username

Description: Name for the VM user to create on the target VM. If left empty, a random name will be generated

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### azure\_arc\_proxy\_command

Description: n/a

### connected\_cluster\_name

Description: n/a

### connected\_cluster\_resource\_group\_name

Description: n/a
<!-- END_TF_DOCS -->
