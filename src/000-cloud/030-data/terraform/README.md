<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Cloud Data

Contains all the resources needed for Cloud based data persistence.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| data\_lake | ./modules/data-lake | n/a |
| schema\_registry | ./modules/schema-registry | n/a |
| storage\_account | ./modules/storage-account | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string id = optional(string) })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| blob\_dns\_zone | Blob private DNS zone object from observability component with id and name properties. If not provided, a new zone will be created when should\_create\_blob\_dns\_zone is true. | ```object({ id = string name = string })``` | `null` | no |
| blob\_soft\_delete\_retention\_days | Number of days to retain deleted blobs | `number` | `7` | no |
| container\_access\_type | The Access Level for the container (blob, container or private) | `string` | `"private"` | no |
| container\_soft\_delete\_retention\_days | Number of days to retain deleted containers | `number` | `7` | no |
| data\_lake\_blob\_container\_name | The name of the Blob Container for the data lake. | `string` | `"data"` | no |
| data\_lake\_data\_contributor\_principal\_id | The Principal ID that will be assigned the 'Storage Blob Data Contributor' role at the Storage Account scope | `string` | `null` | no |
| data\_lake\_data\_owner\_principal\_id | The Principal ID that will be assigned the 'Storage Blob Data Owner' role at the Storage Account scope. (Otherwise, uses the current logged in user) | `string` | `null` | no |
| data\_lake\_filesystem\_name | Name of the Data Lake Gen2 filesystem to create | `string` | `"datalake"` | no |
| file\_share\_name | Name of the file share to create | `string` | `"fileshare"` | no |
| file\_share\_quota\_gb | Maximum size of the file share in GB | `number` | `5` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| private\_endpoint\_subnet\_id | ID of the subnet to deploy the private endpoint | `string` | `null` | no |
| should\_create\_blob\_dns\_zone | Whether to create the blob private DNS zone. Set to false if using a shared DNS zone from observability component. | `bool` | `true` | no |
| should\_create\_data\_lake | Whether or not to create the data lake which includes a Blob Container and Data Lake Filesystem. | `bool` | `true` | no |
| should\_create\_data\_lake\_file\_share | Whether to create a file share | `bool` | `false` | no |
| should\_create\_schema\_registry | Whether to crate the Schema Registry resources. | `bool` | `true` | no |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the storage account | `bool` | `false` | no |
| should\_enable\_public\_network\_access | Whether to enable public network access for the storage account | `bool` | `true` | no |
| storage\_account\_is\_hns\_enabled | Whether to enable Hierarchical Namespace (HNS) for Azure Data Lake Storage Gen2. Note: Azure ML workspaces do not support HNS-enabled storage accounts. | `bool` | `true` | no |
| storage\_account\_kind | Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2) | `string` | `"StorageV2"` | no |
| storage\_account\_replication | Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS) | `string` | `"LRS"` | no |
| storage\_account\_tier | Defines the Tier to use for this storage account (Standard or Premium) | `string` | `"Standard"` | no |
| virtual\_network\_id | The ID of the virtual network to link to the private DNS zones. Required if should\_enable\_private\_endpoint is true. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| data\_lake\_blob\_container\_name | The name for the Data Lake Blob Container. |
| data\_lake\_file\_share\_name | The name for the Data Lake File Share. |
| data\_lake\_filesystem\_name | The name for the Data Lake Gen2 Filesystem. |
| schema\_registry | The new ADR Schema Registry resource. |
| storage\_account | The new Storage Account resource. |
| storage\_account\_private\_dns\_zones | The private DNS zones for Storage Account. |
| storage\_account\_private\_endpoints | The private endpoints for Storage Account. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
