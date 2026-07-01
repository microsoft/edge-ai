<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azurerm   | >= 4.51.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                            | Type        |
|---------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                  | resource    |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name             | Description                                                          | Type                                                                                                                                                                                                                                                             | Default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Required |
|------------------|----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod     | `string`                                                                                                                                                                                                                                                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |   yes    |
| resource\_prefix | Prefix for all resources in this module                              | `string`                                                                                                                                                                                                                                                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc              | `string`                                                                                                                                                                                                                                                         | `"001"`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| schemas          | List of schemas to create in the schema registry with their versions | ```list(object({ name = string display_name = optional(string) description = optional(string) format = optional(string, "JsonSchema/draft-07") type = optional(string, "MessageSchema") versions = map(object({ description = string content = string })) }))``` | ```[ { "description": "Schema for temperature sensor data", "display_name": "Temperature Schema", "format": "JsonSchema/draft-07", "name": "temperature-schema", "type": "MessageSchema", "versions": { "1": { "content": "{\"$schema\":\"http://json-schema.org/draft-07/schema#\",\"name\":\"temperature-schema\",\"type\":\"object\",\"properties\":{\"temperature\":{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"number\"},\"unit\":{\"type\":\"string\"}},\"required\":[\"value\",\"unit\"]}},\"required\":[\"temperature\"]}", "description": "Initial version" } } } ]``` |    no    |
<!-- END_TF_DOCS -->
