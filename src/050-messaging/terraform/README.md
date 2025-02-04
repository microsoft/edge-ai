<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Messaging

Sets up messaging infrastructure and includes deploying a sample
Azure IoT Operations Dataflow to send and receive data from edge to cloud.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| event\_grid | ./modules/event-grid | n/a |
| event\_hubs | ./modules/event-hubs | n/a |
| sample\_event\_grid\_dataflow | ./modules/event-grid-dataflow | n/a |
| sample\_event\_hub\_dataflow | ./modules/event-hub-dataflow | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_custom\_locations | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aio\_dataflow\_profile | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_instance | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| aio\_user\_assigned\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | `"oven"` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
