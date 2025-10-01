<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network Module

Deploys virtual network resources for AKS

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
| [azurerm_subnet.snet_aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.snet_aks_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.snet_aks_node_pool_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.snet_aks_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.snet_aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_nat_gateway_association.snet_aks_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_nat_gateway_association.snet_aks_node_pool_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_nat_gateway_association.snet_aks_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks_node_pool_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for AKS subnets | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| nat\_gateway\_id | NAT gateway resource id for associating AKS subnets | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_enable\_private\_endpoint | Whether to enable private endpoint for AKS cluster. When true, subnet delegations are created. | `bool` | n/a | yes |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet. | `list(string)` | n/a | yes |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet. | `list(string)` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string })``` | n/a | yes |
| node\_pools | Configuration for additional node pool subnets. Map key is used as the node pool name. | ```map(object({ subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) }))``` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| snet\_aks | The subnet created for Azure Kubernetes service. |
| snet\_aks\_node\_pool | The subnets created for Azure Kubernetes service node pools. |
| snet\_aks\_node\_pool\_pod | The subnets created for Azure Kubernetes service node pool pods. |
| snet\_aks\_pod | The subnet created for Azure Kubernetes service pod vnet. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
