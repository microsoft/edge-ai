<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Device Registry Schema Registry

Responsible for creating a Blob Container for the schema, ADR Schema Registry, and a
Storage Blob Data Contributor Role Assignment.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |
| azurerm | n/a |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.schema_registry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_role_assignment.registry_storage_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_container.schema_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | n/a | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| storage\_account | n/a | ```object({ id = string name = string primary_blob_endpoint = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| schema\_registry | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
