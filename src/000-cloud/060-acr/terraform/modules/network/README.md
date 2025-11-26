<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network Module

Deploys virtual network resources for ACR

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_subnet.snet_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.snet_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for the ACR subnet | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| nat\_gateway\_id | NAT gateway resource id for associating the ACR subnet | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_create\_acr\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | n/a | yes |
| should\_enable\_nat\_gateway | Whether to associate the ACR subnet with a NAT gateway for managed egress | `bool` | n/a | yes |
| subnet\_address\_prefixes\_acr | Address prefixes for the ACR subnet | `list(string)` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| snet\_acr | The subnet created for Azure Container Registry private endpoint. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
