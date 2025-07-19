<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network

Creates a virtual network with subnets and associated network security groups for Azure resources.
This component provides the foundational networking infrastructure for cloud resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| location | Azure region to provision all resources in this module. | `string` | n/a | yes |
| resource\_group | The resource group to deploy the virtual network in. | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| virtual\_network\_config | Configuration for the virtual network including address space and subnet prefix. | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.0.0.0/16", "subnet_address_prefix": "10.0.1.0/24" }``` | no |

## Outputs

| Name | Description |
|------|-------------|
| network\_security\_group | The network security group object. |
| subnet\_id | The ID of the subnet. |
| virtual\_network | The virtual network object. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
