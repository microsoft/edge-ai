<!-- BEGIN_TF_DOCS -->
# Edge Device Module

Deploys a Linux VM with an Arc-connected K3s cluster

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azuread

- azurerm

- local

- random

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
- [local_file.ssh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [random_string.vm_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [terraform_data.wait_connected_cluster_exists](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [tls_private_key.vm_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) (resource)
- [azuread_service_principal.custom_locations](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### add\_current\_entra\_user\_cluster\_admin

Description: Only applies if 'environment!=prod'. Adds the current user as cluster-admin cluster role binding

Type: `bool`

### arc\_sp\_client\_id

Description: Service Principal Client ID for connecting to Azure Arc

Type: `string`

### arc\_sp\_secret

Description: Service Principal Secret for connecting to Azure Arc

Type: `string`

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

### vm\_sku\_size

Description: Size of the VM

Type: `string`

### vm\_username

Description: Name for the user to create on the VM. If left empty, a random name will be generated

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### arc\_auto\_upgrade

Description: Enable or disable auto-upgrades of Arc agents. Defaults to "enable".

Type: `string`

Default: `"enable"`

### custom\_locations\_oid

Description: The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

Type: `string`

Default: `""`

## Outputs

The following outputs are exported:

### connected\_cluster\_name

Description: n/a

### public\_ip

Description: n/a

### public\_ssh

Description: n/a

### vm\_id

Description: n/a
<!-- END_TF_DOCS -->