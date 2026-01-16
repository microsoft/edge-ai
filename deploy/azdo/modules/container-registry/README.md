<!-- BEGIN_TF_DOCS -->
# Azure Container Registry for Accelerator

Create a Container Registry to host the artifacts for the Accelerator

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | n/a     |

## Resources

| Name                                                                                                                                                                             | Type     |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry)                                             | resource |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record)                                    | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone)                                            | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)                                                 | resource |

## Inputs

| Name             | Description                                                                                                                                     | Type                                              | Default     | Required |
|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------|-------------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod                                                                                | `string`                                          | n/a         |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc                                                                                         | `string`                                          | n/a         |   yes    |
| resource\_group  | Resource group object containing name and id where resources will be deployed                                                                   | ```object({ name = string location = string })``` | n/a         |   yes    |
| resource\_prefix | Prefix for all resources in this module                                                                                                         | `string`                                          | n/a         |   yes    |
| snet\_acr        | Subnet for the Azure Container Registry private endpoint.                                                                                       | ```object({ id = string })```                     | n/a         |   yes    |
| vnet             | Virtual Network for Container Registry Private DNS Zone.                                                                                        | ```object({ id = string })```                     | n/a         |   yes    |
| acr\_sku         | SKU for the Azure Container Registry. Valid values: Basic, Standard, Premium. Default is "Premium" (Premium is required for private endpoints). | `string`                                          | `"Premium"` |    no    |

## Outputs

| Name | Description                                                   |
|------|---------------------------------------------------------------|
| acr  | The Azure Container Registry resource created by this module. |
<!-- END_TF_DOCS -->
