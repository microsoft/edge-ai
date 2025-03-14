<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Storage Account

Create a new Azure Storage Account with the specified configuration.

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
| [azurerm_private_endpoint.storage_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_kind | Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2) | `string` | n/a | yes |
| account\_replication\_type | Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS) | `string` | n/a | yes |
| account\_tier | Defines the Tier to use for this storage account (Standard or Premium) | `string` | n/a | yes |
| blob\_soft\_delete\_retention\_days | Number of days to retain deleted blobs | `number` | n/a | yes |
| container\_soft\_delete\_retention\_days | Number of days to retain deleted containers | `number` | n/a | yes |
| enable\_private\_endpoint | Enable private endpoint for the storage account | `bool` | n/a | yes |
| environment | Environment name (dev, test, prod) | `string` | n/a | yes |
| instance | Instance identifier to distinguish between multiple instances | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | Prefix to add to all resources | `string` | n/a | yes |
| storage\_account\_name | Name of the storage account | `string` | n/a | yes |
| subnet\_id | ID of the subnet to deploy the private endpoint | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| account\_kind | The Kind of Storage Account. |
| account\_replication\_type | The Replication Type of the Storage Account. |
| account\_tier | The Tier of the Storage Account. |
| id | The ID of the Storage Account. |
| is\_hns\_enabled | Is Hierarchical Namespace enabled? |
| name | The name of the Storage Account. |
| primary\_access\_key | The primary access key for the storage account. |
| primary\_blob\_endpoint | The endpoint URL for blob storage in the primary location. |
| primary\_connection\_string | The connection string associated with the primary location. |
| private\_endpoint | The private endpoint configuration if enabled |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
