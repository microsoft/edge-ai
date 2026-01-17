<!-- BEGIN_TF_DOCS -->
# Azure Device Registry Namespace

Creates an ADR namespace for organizing assets and devices in Azure IoT Operations.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |

## Providers

| Name  | Version  |
|-------|----------|
| azapi | >= 2.3.0 |

## Resources

| Name                                                                                                               | Type     |
|--------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.adr_namespace](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name                               | Description                                                                                                        | Type                                                                                        | Default | Required |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|---------|:--------:|
| adr\_namespace\_name               | The name of the ADR namespace. Must be 3-64 characters, lowercase letters and numbers only, with optional hyphens. | `string`                                                                                    | n/a     |   yes    |
| enable\_system\_assigned\_identity | Whether to enable system-assigned managed identity for the namespace.                                              | `bool`                                                                                      | n/a     |   yes    |
| location                           | Location for all resources in this module                                                                          | `string`                                                                                    | n/a     |   yes    |
| messaging\_endpoints               | Dictionary of messaging endpoints for the namespace.                                                               | ```map(object({ endpointType = string address = string resourceId = optional(string) }))``` | n/a     |   yes    |
| resource\_group                    | The resource group where the namespace will be created.                                                            | ```object({ id = string name = string })```                                                 | n/a     |   yes    |

## Outputs

| Name           | Description                                      |
|----------------|--------------------------------------------------|
| adr\_namespace | The complete ADR namespace resource information. |
<!-- END_TF_DOCS -->
