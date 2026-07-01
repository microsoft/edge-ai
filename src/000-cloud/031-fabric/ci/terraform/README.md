<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azurerm   | >= 4.51.0        |
| fabric    | 1.3.0            |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                            | Type        |
|---------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                  | resource    |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                               | Description                                                                                                        | Type           | Default | Required |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------|----------------|---------|:--------:|
| environment                        | Environment for all resources in this module: dev, test, or prod                                                   | `string`       | n/a     |   yes    |
| resource\_prefix                   | Prefix for all resources in this module                                                                            | `string`       | n/a     |   yes    |
| fabric\_capacity\_admins           | List of AAD object IDs for Fabric capacity administrators. Required when creating a capacity.                      | `list(string)` | `[]`    |    no    |
| fabric\_capacity\_name             | The name of the Microsoft Fabric capacity. Otherwise, 'cap{resource\_prefix\_no\_hyphens}{environment}{instance}'. | `string`       | `null`  |    no    |
| fabric\_workspace\_name            | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource\_prefix}-{environment}-{instance}'            | `string`       | `null`  |    no    |
| instance                           | Instance identifier for naming resources: 001, 002, etc                                                            | `string`       | `"001"` |    no    |
| should\_create\_fabric\_capacity   | Whether to create a new Fabric capacity or use an existing one.                                                    | `bool`         | `false` |    no    |
| should\_create\_fabric\_eventhouse | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios.                              | `bool`         | `false` |    no    |
| should\_create\_fabric\_lakehouse  | Whether to create a Microsoft Fabric lakehouse.                                                                    | `bool`         | `false` |    no    |
| should\_create\_fabric\_workspace  | Whether to create a new Microsoft Fabric workspace or use an existing one.                                         | `bool`         | `false` |    no    |
<!-- END_TF_DOCS -->
