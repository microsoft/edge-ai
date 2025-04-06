<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Data Lake

Creates Azure Storage Container, Storage File Share, and a Data Lake Filesystem along with setting up
role assignments for provided principal IDs.

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
| [azurerm_storage_container.data_lake](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_data_lake_gen2_filesystem.data_lake](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem) | resource |
| [azurerm_storage_share.data_lake](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| container\_access\_type | The Access Level for the container (blob, container or private) | `string` | n/a | yes |
| data\_lake\_blob\_container\_name | The name of the Blob Container for the data lake. | `string` | n/a | yes |
| data\_lake\_data\_contributor\_principal\_id | The Principal ID that will be assigned the 'Storage Blob Data Contributor' role at the Storage Account scope. | `string` | n/a | yes |
| data\_lake\_data\_owner\_principal\_id | The Principal ID that will be assigned the 'Storage Blob Data Owner' role at the Storage Account scope. (Otherwise, uses the current logged in user) | `string` | n/a | yes |
| data\_lake\_filesystem\_name | Name of the Data Lake Gen2 filesystem | `string` | n/a | yes |
| file\_share\_name | Name of the file share | `string` | n/a | yes |
| file\_share\_quota\_gb | Quota of the file share in GB | `number` | n/a | yes |
| should\_create\_data\_lake\_file\_share | Whether to create a file share | `bool` | n/a | yes |
| storage\_account | n/a | ```object({ id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| blob\_container\_id | The ID for the Data Lake Blob Container. |
| blob\_container\_name | The name for the Data Lake Blob Container. |
| file\_share\_name | The name for the Data Lake File Share. |
| filesystem\_name | The name for the Data Lake Gen2 Filesystem. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
