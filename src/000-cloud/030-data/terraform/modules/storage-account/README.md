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
| random | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_private_endpoint.storage_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [random_string.random_clean_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_kind | Defines the Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage or StorageV2) | `string` | n/a | yes |
| account\_replication\_type | Defines the type of replication to use for this storage account (LRS, GRS, RAGRS, ZRS) | `string` | n/a | yes |
| account\_tier | Defines the Tier to use for this storage account (Standard or Premium) | `string` | n/a | yes |
| blob\_soft\_delete\_retention\_days | Number of days to retain deleted blobs | `number` | n/a | yes |
| container\_soft\_delete\_retention\_days | Number of days to retain deleted containers | `number` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| private\_endpoint\_subnet\_id | ID of the subnet to deploy the private endpoint | `string` | n/a | yes |
| resource\_group | n/a | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the storage account | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| storage\_account | The newly created Storage Account. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
