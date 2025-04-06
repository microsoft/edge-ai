/**
 * # Cloud Data
 *
 * Contains all the resources needed for Cloud based data persistence.
 */


data "azurerm_client_config" "current" {}

module "storage_account" {
  source = "./modules/storage-account"

  account_tier                         = var.storage_account_tier
  account_replication_type             = var.storage_account_replication
  account_kind                         = var.storage_account_kind
  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  environment                          = var.environment
  instance                             = var.instance
  location                             = var.location
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  resource_group                       = var.resource_group
  resource_prefix                      = var.resource_prefix
  should_enable_private_endpoint       = var.should_enable_private_endpoint
}

module "schema_registry" {
  count = var.should_create_schema_registry ? 1 : 0

  source = "./modules/schema-registry"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_group  = var.resource_group
  resource_prefix = var.resource_prefix
  storage_account = module.storage_account.storage_account
}

module "data_lake" {
  count = var.should_create_data_lake ? 1 : 0

  source = "./modules/data-lake"

  container_access_type                   = var.container_access_type
  data_lake_blob_container_name           = var.data_lake_blob_container_name
  data_lake_filesystem_name               = var.data_lake_filesystem_name
  data_lake_data_owner_principal_id       = coalesce(var.data_lake_data_owner_principal_id, data.azurerm_client_config.current.object_id)
  data_lake_data_contributor_principal_id = var.data_lake_data_contributor_principal_id
  file_share_name                         = var.file_share_name
  file_share_quota_gb                     = var.file_share_quota_gb
  should_create_data_lake_file_share      = var.should_create_data_lake_file_share
  storage_account                         = module.storage_account.storage_account
}
