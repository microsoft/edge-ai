<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Storage Container

Create a new Azure Storage Container with the specified configuration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.data_lake_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.data_lake_owner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_container.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_data_lake_gen2_filesystem.data_lake](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem) | resource |
| [azurerm_storage_share.file_share](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| container\_access\_type | The Access Level for the container (blob, container or private) | `string` | n/a | yes |
| container\_name | Name of the storage container | `string` | n/a | yes |
| create\_file\_share | Whether to create a file share | `bool` | n/a | yes |
| data\_lake\_filesystem\_name | Name of the Data Lake Gen2 filesystem | `string` | n/a | yes |
| file\_share\_name | Name of the file share | `string` | n/a | yes |
| file\_share\_quota\_gb | Quota of the file share in GB | `number` | n/a | yes |
| managed\_identity\_principal\_id | Principal ID of the managed identity to assign roles to | `string` | n/a | yes |
| storage\_account\_id | ID of the storage account | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| container\_id | The ID of the storage container |
| container\_name | The name of the storage container |
| data\_lake\_filesystem\_name | The name of the Data Lake Gen2 filesystem |
| file\_share\_name | The name of the file share (if created) |
| role\_assignments\_contributor | The Storage Blob Data Contributor role assignments |
| role\_assignments\_owner | The Storage Blob Data Owner role assignments |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
