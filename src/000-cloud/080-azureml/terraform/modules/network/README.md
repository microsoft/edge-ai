<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network Module

Deploys virtual network resources for Azure ML compute clusters

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
| [azurerm_subnet.snet_azureml](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.snet_azureml](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_azureml](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for Azure ML subnets | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| nat\_gateway\_id | NAT gateway resource id for associating the Azure ML subnet | `string` | n/a | yes |
| network\_security\_group | Network security group to apply to the subnets. | ```object({ id = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed. | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| should\_associate\_network\_security\_group | Whether to associate the Azure ML subnet with a network security group. | `bool` | n/a | yes |
| should\_enable\_nat\_gateway | Whether to associate the Azure ML subnet with a NAT gateway for managed egress | `bool` | n/a | yes |
| subnet\_address\_prefixes\_azureml | Address prefixes for the Azure ML compute cluster subnet. | `list(string)` | n/a | yes |
| virtual\_network | Virtual network where subnets will be created. | ```object({ name = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| snet\_azureml | The subnet created for Azure ML compute cluster. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
