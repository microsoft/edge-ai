<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network

Creates a virtual network with subnets and associated network security groups for Azure resources.
This component provides the foundational networking infrastructure for cloud resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_dns_servers.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_dns_servers) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| nat\_gateway | ./modules/nat-gateway | n/a |
| private\_resolver | ./modules/private-resolver | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for subnets created by this component | `bool` | `false` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| nat\_gateway\_idle\_timeout\_minutes | Idle timeout in minutes for NAT gateway connections | `number` | `4` | no |
| nat\_gateway\_public\_ip\_count | Number of public IP addresses to associate with the NAT gateway (example: 2) | `number` | `1` | no |
| nat\_gateway\_zones | Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2']) | `list(string)` | `[]` | no |
| resolver\_subnet\_address\_prefix | Address prefix for the Private Resolver subnet (Must be /28 or larger and not overlap with other subnets) | `string` | `"10.0.9.0/28"` | no |
| should\_enable\_nat\_gateway | Whether to enable managed NAT gateway support for component subnets when default outbound access is disabled | `bool` | `true` | no |
| should\_enable\_private\_resolver | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints | `bool` | `false` | no |
| virtual\_network\_config | Configuration for the virtual network including address space and subnet prefix | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.0.0.0/16", "subnet_address_prefix": "10.0.1.0/24" }``` | no |

## Outputs

| Name | Description |
|------|-------------|
| dns\_server\_ip | The IP address of the Private Resolver inbound endpoint to use as DNS server |
| nat\_gateway | The NAT gateway resource when managed outbound access is enabled |
| nat\_gateway\_public\_ips | Public IP resources associated with the NAT gateway keyed by name |
| network\_security\_group | The network security group object. |
| private\_resolver | The Azure Private Resolver configuration and details |
| subnet\_id | The ID of the subnet. |
| virtual\_network | The virtual network object. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
