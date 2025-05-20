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
| event\_grid | ./modules/event-grid | n/a |
| event\_hubs | ./modules/event-hubs | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_identity | n/a | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| event\_grid\_capacity | Specifies the Capacity / Throughput Units for Event Grid namespace. | `number` | `1` | no |
| event\_grid\_max\_client\_sessions | Specifies the maximum number of client sessions per authentication name. | `number` | `8` | no |
| event\_grid\_topic\_name | Topic template name to create in the Event Grid namespace. | `string` | `"default"` | no |
| event\_hub\_capacity | Specifies the Capacity / Throughput Units for Event Hub namespace. | `number` | `1` | no |
| event\_hub\_message\_retention | Specifies the number of days to retain events for Event Hub, from 1 to 7 days. | `number` | `1` | no |
| event\_hub\_partition\_count | Specifies the number of partitions for Event Hub. Valid values are from 1 to 32. | `number` | `1` | no |
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
