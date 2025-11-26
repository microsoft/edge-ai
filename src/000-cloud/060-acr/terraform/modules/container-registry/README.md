<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Container Registry for Accelerator

Deploys Azure Container Registry with a private endpoint and private DNS zone.

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
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.data_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allow\_trusted\_services | Whether trusted Azure services can bypass registry network rules | `bool` | n/a | yes |
| allowed\_public\_ip\_ranges | CIDR ranges permitted to reach the registry public endpoint | `list(string)` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| public\_network\_access\_enabled | Whether to enable the registry public endpoint alongside private connectivity | `bool` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_create\_acr\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | n/a | yes |
| should\_enable\_data\_endpoints | Whether to enable dedicated data endpoints for the registry | `bool` | n/a | yes |
| sku | SKU name for the resource | `string` | n/a | yes |
| snet\_acr | Subnet for the Azure Container Registry private endpoint. | ```object({ id = string })``` | n/a | yes |
| vnet | Virtual Network for Container Registry Private DNS Zone. | ```object({ id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| acr | The Azure Container Registry resource created by this module. |
| private\_dns\_zone | The private DNS zone for Azure Container Registry. |
| private\_endpoint | The private endpoint resource for Azure Container Registry. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
