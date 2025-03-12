# Azure Storage Terraform Module

This Terraform module creates Azure Storage resources for edge solutions. It includes the setup of:

- Azure Storage Account with configurable settings
- Storage Container for blob data storage
- Optional File Share for file storage
- Optional Private Endpoint for secure connectivity

## Usage

Include this module in your Terraform configuration:

```hcl
module "storage" {
  source = "./path/to/this/module"

  resource_prefix           = "myproject"
  location                  = "eastus2"
  storage_account_tier      = "Standard"
  storage_account_replication = "LRS"
  container_name            = "data"

  # Optional configuration
  create_file_share         = true
  file_share_name           = "configs"
  enable_private_endpoint   = true
  subnet_id                 = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."

  tags = {
    Environment = "Production"
    Project     = "Edge Computing"
  }
}
```

## Inputs

| Name                        | Description                                       | Type          | Default       | Required |
|-----------------------------|---------------------------------------------------|---------------|---------------|:--------:|
| resource_prefix             | Prefix for all resources created by this template | `string`      | n/a           |   yes    |
| location                    | Azure region where resources will be created      | `string`      | n/a           |   yes    |
| storage_account_tier        | Defines the Tier to use for this storage account  | `string`      | `"Standard"`  |    no    |
| storage_account_replication | Defines the type of replication to use            | `string`      | `"LRS"`       |    no    |
| storage_account_kind        | Defines the Kind of account                       | `string`      | `"StorageV2"` |    no    |
| container_name              | Name of the container to create                   | `string`      | `"data"`      |    no    |
| container_access_type       | Access level for the container                    | `string`      | `"private"`   |    no    |
| create_file_share           | Whether to create a file share                    | `bool`        | `false`       |    no    |
| file_share_name             | Name of the file share to create                  | `string`      | `"fileshare"` |    no    |
| file_share_quota_gb         | Maximum size of the file share in GB              | `number`      | `5`           |    no    |
| enable_private_endpoint     | Whether to create a private endpoint              | `bool`        | `false`       |    no    |
| subnet_id                   | ID of the subnet for private endpoint             | `string`      | `""`          |    no    |
| tags                        | A map of tags to add to all resources             | `map(string)` | `{}`          |    no    |

## Outputs

| Name                      | Description                                           |
|---------------------------|-------------------------------------------------------|
| storage_account_id        | The ID of the Storage Account                         |
| storage_account_name      | The name of the Storage Account                       |
| primary_blob_endpoint     | The primary blob endpoint URL                         |
| primary_connection_string | The primary connection string for the storage account |
| container_name            | The name of the storage container                     |
| file_share_name           | The name of the file share (if created)               |
