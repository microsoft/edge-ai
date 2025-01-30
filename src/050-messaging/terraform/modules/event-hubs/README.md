<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Event Hubs

Create a new Event Hub namespace and Event Hub and optionally assign the current AIO extension the Azure Event Hubs Data Sender role.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | 2.1.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_eventhub.destination_eh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_namespace.destination_event_hub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_role_assignment.data_sender](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_uami\_principal\_id | Principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | Name of the pre-existing resource group in which to create resources | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| capacity | Specifies the Capacity / Throughput Units for a Standard SKU namespace. Valid values range from 1 - 20. | `number` | `1` | no |
| message\_retention | Specifies the number of days to retain events for this Event Hub, from 1 to 7 days. | `number` | `1` | no |
| partition\_count | Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32. | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| event\_hub | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
