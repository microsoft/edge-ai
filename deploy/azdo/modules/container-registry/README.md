<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Container Registry for Accelerator

Create a Container Registry to host the artifacts for the Accelerator

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
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dns\_zone | Private DNS zone for the Azure Container Registry private endpoint. | ```object({ name = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| resource\_group | Resource group for all resources in this module. | ```object({ name = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| snet\_acr | Subnet for the Azure Container Registry private endpoint. | ```object({ id = string })``` | n/a | yes |
| vnet | Virtual Network for Key Vault Private DNS Zone. | ```object({ name = string })``` | n/a | yes |
| sku | SKU for the Azure Container Registry. Options are Basic, Standard, Premium. Default is Premium because of the need for private endpoints. | `string` | `"Premium"` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr | The Azure Container Registry resource created by this module. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
