<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azuread   | >= 3.0.2         |
| azurerm   | >= 4.51.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                                                 | Type        |
|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                       | resource    |
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry)              | data source |
| [azurerm_network_security_group.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_security_group) | data source |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)                      | data source |
| [azurerm_virtual_network.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network)               | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name             | Description                                                      | Type     | Default | Required |
|------------------|------------------------------------------------------------------|----------|---------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod | `string` | n/a     |   yes    |
| location         | Azure region where all resources will be deployed                | `string` | n/a     |   yes    |
| resource\_prefix | Prefix for all resources in this module                          | `string` | n/a     |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc          | `string` | `"001"` |    no    |
<!-- END_TF_DOCS -->
