<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Messaging

Creates Azure IoT Operations dataflows for messaging scenarios including
Event Hub and Event Grid endpoints for edge-to-cloud data transmission.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| sample\_eventgrid\_dataflow | ./modules/eventgrid | n/a |
| sample\_eventhub\_dataflow | ./modules/eventhub | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_custom\_locations | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aio\_dataflow\_profile | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| aio\_instance | n/a | ```object({ id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | `"oven"` | no |
| eventgrid | Values for the existing Event Grid | ```object({ topic_name = string endpoint = string })``` | `null` | no |
| eventhub | Values for the existing Event Hub namespace and Event Hub | ```object({ namespace_name = string eventhub_name = string })``` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| should\_create\_eventgrid\_dataflows | Whether to create event grid dataflows. | `bool` | `true` | no |
| should\_create\_eventhub\_dataflows | Whether to create event hub dataflows. | `bool` | `true` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
