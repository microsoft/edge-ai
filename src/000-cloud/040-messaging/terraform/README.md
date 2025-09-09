<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Messaging

Sets up messaging infrastructure and includes deploying a sample
Azure IoT Operations Dataflow to send and receive data from edge to cloud.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| app\_service\_plan | ./modules/app-service-plan | n/a |
| azure\_functions | ./modules/azure-functions | n/a |
| eventgrid | ./modules/eventgrid | n/a |
| eventhub | ./modules/eventhub | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| app\_service\_plan\_os\_type | The operating system type for the App Service Plan. | `string` | `"Linux"` | no |
| app\_service\_plan\_sku\_name | The SKU name for the App Service Plan. | `string` | `"B1"` | no |
| eventgrid\_capacity | Specifies the Capacity / Throughput Units for Event Grid namespace. | `number` | `1` | no |
| eventgrid\_max\_client\_sessions | Specifies the maximum number of client sessions per authentication name. | `number` | `8` | no |
| eventgrid\_topic\_name | Topic template name to create in the Event Grid namespace. | `string` | `"default"` | no |
| eventhub\_capacity | Specifies the Capacity / Throughput Units for Event Hub namespace. | `number` | `1` | no |
| eventhubs | Per-Event Hub configuration. Keys are Event Hub names.  - **Message retention**: Specifies the number of days to retain events for this Event Hub, from 1 to 7. - **Partition count**: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32. - **Consumer group user metadata**: A placeholder to store user-defined string data with maximum length 1024.   It can be used to store descriptive data, such as list of teams and their contact information,   or user-defined configuration settings. | ```map(object({ message_retention = optional(number, 1) partition_count = optional(number, 1) consumer_groups = optional(map(object({ user_metadata = optional(string, null) })), {}) }))``` | ```{ "evh-aio-sample": {} }``` | no |
| function\_app\_settings | A map of key-value pairs for App Settings. | `map(string)` | `{}` | no |
| function\_cors\_allowed\_origins | A list of origins that should be allowed to make cross-origin calls. | `list(string)` | ```[ "*" ]``` | no |
| function\_cors\_support\_credentials | Whether CORS requests with credentials are allowed. | `bool` | `false` | no |
| function\_node\_version | The version of Node.js to use. | `string` | `"18"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| should\_create\_azure\_functions | Whether to create the Azure Functions resources including App Service Plan | `bool` | `false` | no |
| should\_create\_eventgrid | Whether to create the Event Grid resources. | `bool` | `true` | no |
| should\_create\_eventhub | Whether to create the Event Hubs resources. | `bool` | `true` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_service\_plan | App Service Plan configuration and details. |
| eventgrid | Event Grid configuration including topic name and endpoint |
| eventhub\_namespace | Event Hub namespace configuration |
| eventhubs | Event Hub(s) configuration |
| function\_app | Function App configuration and details. |
| function\_storage\_account | Storage Account used by the Function App. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
