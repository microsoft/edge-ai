<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| random | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.random_clean_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| data\_lake | ./modules/data-lake | n/a |
| storage\_account | ./modules/storage-account | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| instance | The instance identifier for the deployment | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | The prefix to use for resource names | `string` | n/a | yes |
| blob\_soft\_delete\_retention\_days | Number of days to retain deleted blobs | `number` | `7` | no |
| container\_access\_type | The Access Level for the container (blob, container or private) | `string` | `"private"` | no |
| container\_name | Name of the container to create | `string` | `"data"` | no |
| container\_soft\_delete\_retention\_days | Number of days to retain deleted containers | `number` | `7` | no |
| create\_file\_share | Whether to create a file share | `bool` | `false` | no |
| data\_lake\_filesystem\_name | Name of the Data Lake Gen2 filesystem to create | `string` | `"datalake"` | no |
| enable\_private\_endpoint | Whether to create a private endpoint for the storage account | `bool` | `false` | no |
| file\_share\_name | Name of the file share to create | `string` | `"fileshare"` | no |
| file\_share\_quota\_gb | Maximum size of the file share in GB | `number` | `5` | no |
| managed\_identity\_principal\_id | Principal ID of a managed identity that should be granted Storage Blob Data Contributor access | `string` | `""` | no |
| storage\_account\_kind | Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2) | `string` | `"StorageV2"` | no |
| storage\_account\_replication | Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS) | `string` | `"LRS"` | no |
| storage\_account\_tier | Defines the Tier to use for this storage account (Standard or Premium) | `string` | `"Standard"` | no |
| subnet\_id | ID of the subnet to deploy the private endpoint | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| container\_name | The name of the storage container |
| data\_lake\_filesystem\_name | The name of the Data Lake Gen2 filesystem |
| file\_share\_name | The name of the file share (if created) |
| primary\_connection\_string | Primary connection string of the Storage Account |
| storage\_account\_id | ID of the Storage Account |
| storage\_account\_name | Name of the Storage Account |
| storage\_account\_primary\_blob\_endpoint | Primary endpoint for blob service |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
