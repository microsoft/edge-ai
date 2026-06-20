<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azurerm   | >= 4.51.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                                            | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                  | resource    |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)                 | data source |
| [azurerm_user_assigned_identity.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Type                                                                                                                                                                                         | Default                        | Required |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `string`                                                                                                                                                                                     | n/a                            |   yes    |
| resource\_prefix | Prefix for all resources in this module                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `string`                                                                                                                                                                                     | n/a                            |   yes    |
| eventhubs        | Per-Event Hub configuration. Keys are Event Hub names.  - **Message retention**: Specifies the number of days to retain events for this Event Hub, from 1 to 7. - **Partition count**: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32. - **Consumer group user metadata**: A placeholder to store user-defined string data with maximum length 1024.   It can be used to store descriptive data, such as list of teams and their contact information,   or user-defined configuration settings. | ```map(object({ message_retention = optional(number, 1) partition_count = optional(number, 1) consumer_groups = optional(map(object({ user_metadata = optional(string, null) })), {}) }))``` | ```{ "evh-aio-sample": {} }``` |    no    |
| instance         | Instance identifier for naming resources: 001, 002, etc                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `string`                                                                                                                                                                                     | `"001"`                        |    no    |
<!-- END_TF_DOCS -->
