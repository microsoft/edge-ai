<!-- BEGIN_TF_DOCS -->
# Dataflow Graphs Module

Creates Azure IoT Operations dataflow graphs for processing data through WASM operators
or standard dataflow nodes. Supports source, destination, and graph-based processing nodes.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.0.1        |

## Providers

| Name  | Version  |
|-------|----------|
| azapi | >= 2.0.1 |

## Resources

| Name                                                                                                                | Type     |
|---------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.dataflow_graph](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name                   | Description                                                      | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Default | Required |
|------------------------|------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| aio\_dataflow\_profile | The AIO dataflow profile object                                  | ```object({ id = string })```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | n/a     |   yes    |
| custom\_location       | The custom location object                                       | ```object({ id = string })```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | n/a     |   yes    |
| dataflow\_graphs       | List of dataflow graphs to create with their node configurations | ```list(object({ name = string mode = optional(string) request_disk_persistence = optional(string) nodes = list(object({ nodeType = string name = string sourceSettings = optional(object({ endpointRef = string assetRef = optional(string) dataSources = list(string) })) graphSettings = optional(object({ registryEndpointRef = string artifact = string configuration = optional(list(object({ key = string value = string }))) })) destinationSettings = optional(object({ endpointRef = string dataDestination = string headers = optional(list(object({ actionType = string key = string value = optional(string) }))) })) })) node_connections = list(object({ from = object({ name = string schema = optional(object({ schemaRef = string serializationFormat = optional(string) })) }) to = object({ name = string }) })) }))``` | n/a     |   yes    |

## Outputs

| Name             | Description                              |
|------------------|------------------------------------------|
| dataflow\_graphs | Map of dataflow graph resources by name. |
<!-- END_TF_DOCS -->
