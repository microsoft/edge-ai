<!-- BEGIN_TF_DOCS -->
# Azure Event Hubs

Create a new Event Hub namespace and Event Hub and optionally assign the current AIO extension the Azure Event Hubs Data Sender role.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_eventhub.destination_eh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) (resource)
- [azurerm_eventhub_namespace.destination_event_hub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) (resource)
- [azurerm_role_assignment.data_sender](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)

## Required Inputs

The following input variables are required:

### aio\_uami\_principal\_id

Description: Principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### capacity

Description: Specifies the Capacity / Throughput Units for a Standard SKU namespace. Valid values range from 1 - 20.

Type: `number`

Default: `1`

### message\_retention

Description: Specifies the number of days to retain events for this Event Hub, from 1 to 7 days.

Type: `number`

Default: `1`

### partition\_count

Description: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32.

Type: `number`

Default: `1`

## Outputs

The following outputs are exported:

### event\_hub

Description: n/a
<!-- END_TF_DOCS -->
