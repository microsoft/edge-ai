<!-- BEGIN_TF_DOCS -->
# Azure Device Registry Schema Registry

Responsible for creating a Blob Container for the schema, ADR Schema Registry, and a
Storage Blob Data Contributor Role Assignment.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |
| time      | >= 0.9.0        |

## Providers

| Name      | Version  |
|-----------|----------|
| azapi     | >= 2.3.0 |
| azurerm   | n/a      |
| terraform | n/a      |
| time      | >= 0.9.0 |

## Resources

| Name                                                                                                                                                              | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.schema_registry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                                              | resource    |
| [azurerm_role_assignment.registry_storage_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)           | resource    |
| [azurerm_role_assignment.schema_container_blob_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource    |
| [azurerm_storage_container.schema_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container)                   | resource    |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                    | resource    |
| [time_sleep.wait_for_rbac_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)                                        | resource    |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config)                                 | data source |

## Inputs

| Name                                   | Description                                                                                                                                                                                | Type                                                                       | Default | Required |
|----------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------|---------|:--------:|
| environment                            | Environment for all resources in this module: dev, test, or prod                                                                                                                           | `string`                                                                   | n/a     |   yes    |
| instance                               | Instance identifier for naming resources: 001, 002, etc                                                                                                                                    | `string`                                                                   | n/a     |   yes    |
| location                               | Azure region where all resources will be deployed                                                                                                                                          | `string`                                                                   | n/a     |   yes    |
| resource\_group                        | Resource group object containing name and id where resources will be deployed                                                                                                              | ```object({ id = string name = string })```                                | n/a     |   yes    |
| resource\_prefix                       | Prefix for all resources in this module                                                                                                                                                    | `string`                                                                   | n/a     |   yes    |
| storage\_account                       | n/a                                                                                                                                                                                        | ```object({ id = string name = string primary_blob_endpoint = string })``` | n/a     |   yes    |
| blob\_data\_contributor\_principal\_id | The principal ID that will be assigned the 'Storage Blob Data Contributor' role on the schemas container so it can upload schema versions. Defaults to the current Azure client when null. | `string`                                                                   | `null`  |    no    |

## Outputs

| Name             | Description |
|------------------|-------------|
| schema\_registry | n/a         |
<!-- END_TF_DOCS -->
