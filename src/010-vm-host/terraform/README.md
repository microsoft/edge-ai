<!-- BEGIN_TF_DOCS -->
# VM Host

Deploys a Linux VM with an Arc-connected K3s cluster

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azuread (>= 3.0.2)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azurerm (>= 4.8.0)

- local

- terraform

- tls

## Resources

The following resources are used by this module:

- [azurerm_linux_virtual_machine.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) (resource)
- [azurerm_network_interface.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_network_security_group.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_public_ip.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_subnet.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_virtual_network.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [local_sensitive_file.ssh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) (resource)
- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [tls_private_key.vm_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) (resource)
- [azurerm_resource_group.aio_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [azurerm_user_assigned_identity.arc_onboarding](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) (data source)

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

### arc\_onboarding\_user\_managed\_identity\_name

Description: If using, the User Assigned Managed Identity name with 'Kubernetes Cluster - Azure Arc Onboarding' permissions.

Type: `string`

Default: `null`

### enable\_arc\_onboarding\_user\_managed\_identity

Description: n/a

Type: `string`

Default: `true`

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`

### vm\_sku\_size

Description: Size of the VM

Type: `string`

Default: `"Standard_D8s_v3"`

### vm\_username

Description: Name for the VM user to create on the target VM. If left empty, a random user name will be generated

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### linux\_virtual\_machine\_name

Description: n/a

### public\_ip

Description: n/a

### public\_ssh

Description: n/a

### public\_ssh\_permissions

Description: n/a

### username

Description: n/a

### vm\_id

Description: n/a
<!-- END_TF_DOCS -->
