<!-- BEGIN_TF_DOCS -->
# Dataflow Module

Creates Azure IoT Operations dataflows for processing data through source,
built-in transformation, and destination operations.

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

| Name                                                                                                          | Type     |
|---------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.dataflow](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name                   | Description                                                     | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Default | Required |
|------------------------|-----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| aio\_dataflow\_profile | The AIO dataflow profile object                                 | ```object({ id = string })```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| custom\_location       | The custom location object                                      | ```object({ id = string })```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| dataflows              | List of dataflows to create with their operation configurations | ```list(object({ name = string mode = optional(string) request_disk_persistence = optional(string) operations = list(object({ operationType = string name = optional(string) sourceSettings = optional(object({ endpointRef = string assetRef = optional(string) serializationFormat = optional(string) schemaRef = optional(string) dataSources = list(string) })) builtInTransformationSettings = optional(object({ serializationFormat = optional(string) schemaRef = optional(string) datasets = optional(list(object({ key = string description = optional(string) schemaRef = optional(string) inputs = list(string) expression = string }))) filter = optional(list(object({ type = optional(string) description = optional(string) inputs = list(string) expression = string }))) map = optional(list(object({ type = optional(string) description = optional(string) inputs = list(string) expression = optional(string) output = string }))) })) destinationSettings = optional(object({ endpointRef = string dataDestination = string })) })) }))``` | n/a     |   yes    |

## Outputs

| Name      | Description                        |
|-----------|------------------------------------|
| dataflows | Map of dataflow resources by name. |
<!-- END_TF_DOCS -->
