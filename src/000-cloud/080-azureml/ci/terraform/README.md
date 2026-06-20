<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azurerm   | >= 4.51.0        |
| tls       | >= 4.0.0         |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                                                 | Type        |
|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                       | resource    |
| [azurerm_application_insights.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_insights)     | data source |
| [azurerm_container_registry.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry)         | data source |
| [azurerm_key_vault.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault)                           | data source |
| [azurerm_network_security_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_security_group) | data source |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)                 | data source |
| [azurerm_storage_account.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account)               | data source |
| [azurerm_virtual_network.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network)               | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name             | Description                                                       | Type     | Default | Required |
|------------------|-------------------------------------------------------------------|----------|---------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod. | `string` | n/a     |   yes    |
| location         | Location for all resources in this module.                        | `string` | n/a     |   yes    |
| resource\_prefix | Prefix for all resources in this module.                          | `string` | n/a     |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc...        | `string` | `"001"` |    no    |
<!-- END_TF_DOCS -->
