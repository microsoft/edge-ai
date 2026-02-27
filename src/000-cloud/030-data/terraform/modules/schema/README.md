<!-- BEGIN_TF_DOCS -->
# Schema Module

Creates schemas and optional schema versions in an Azure Device Registry Schema Registry.
This module is designed for defining message schemas used by Azure IoT Operations dataflows.

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
| [azapi_resource.schema](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)         | resource |
| [azapi_resource.schema_version](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name                  | Description                                                          | Type                                                                                                                                                                                                                                                             | Default | Required |
|-----------------------|----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| adr\_schema\_registry | The Azure Device Registry schema registry object                     | ```object({ id = string })```                                                                                                                                                                                                                                    | n/a     |   yes    |
| schemas               | List of schemas to create in the schema registry with their versions | ```list(object({ name = string display_name = optional(string) description = optional(string) format = optional(string, "JsonSchema/draft-07") type = optional(string, "MessageSchema") versions = map(object({ description = string content = string })) }))``` | n/a     |   yes    |

## Outputs

| Name    | Description                                          |
|---------|------------------------------------------------------|
| schemas | Map of schema resources by name with their versions. |
<!-- END_TF_DOCS -->
