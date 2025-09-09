<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Event Hubs

Create a new Event Hub namespace and Event Hub and assign the AIO instance UAMI the Azure Event Hubs Data Sender role.

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
| [azurerm_eventhub.destination_eh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_consumer_group.destination_eh_cg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_consumer_group) | resource |
| [azurerm_eventhub_namespace.destination_eventhub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_role_assignment.data_sender](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_uami\_principal\_id | Principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| capacity | Specifies the Capacity / Throughput Units for a Standard SKU namespace. | `number` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| eventhubs | Per-Event Hub configuration. Keys are Event Hub names.  - **Message retention**: Specifies the number of days to retain events for this Event Hub, from 1 to 7. - **Partition count**: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32. - **Consumer group user metadata**: A placeholder to store user-defined string data with maximum length 1024.   It can be used to store descriptive data, such as list of teams and their contact information,   or user-defined configuration settings. | ```map(object({ message_retention = optional(number, 1) partition_count = optional(number, 1) consumer_groups = optional(map(object({ user_metadata = optional(string, null) })), {}) }))``` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| eventhub\_namespace | Event Hub namespace values. |
| eventhubs | Event Hub values. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
