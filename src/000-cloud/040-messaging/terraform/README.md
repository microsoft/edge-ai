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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| should\_create\_event\_grid | Whether to create the Event Grid resources. | `bool` | `true` | no |
| should\_create\_event\_hubs | Whether to create the Event Hubs resources. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| event\_grid | Event Grid configuration including topic name and endpoint |
| event\_grid\_endpoint | The Event Grid endpoint URL for MQTT connections |
| event\_hub | Event Hub configuration including connection string and endpoint |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
