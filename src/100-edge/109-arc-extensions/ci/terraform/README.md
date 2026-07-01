<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azurerm   | >= 4.8.0         |

## Providers

| Name      | Version  |
|-----------|----------|
| azapi     | >= 2.3.0 |
| azurerm   | >= 4.8.0 |
| terraform | n/a      |

## Resources

| Name                                                                                                                                       | Type        |
|--------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                             | resource    |
| [azapi_resource.arc_connected_cluster](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource)              | data source |
| [azurerm_resource_group.arc_extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name             | Description                                                      | Type     | Default | Required |
|------------------|------------------------------------------------------------------|----------|---------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod | `string` | n/a     |   yes    |
| resource\_prefix | Prefix for all resources in this module                          | `string` | n/a     |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc          | `string` | `"001"` |    no    |
<!-- END_TF_DOCS -->
