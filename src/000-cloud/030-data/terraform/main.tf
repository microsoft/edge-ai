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
  is_hns_enabled                       = var.storage_account_is_hns_enabled
  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  environment                          = var.environment
  instance                             = var.instance
  location                             = var.location
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  resource_group                       = var.resource_group
  resource_prefix                      = var.resource_prefix
  should_enable_private_endpoint       = var.should_enable_private_endpoint
  should_enable_public_network_access  = var.should_enable_public_network_access
  virtual_network_id                   = var.virtual_network_id
  should_create_blob_dns_zone          = var.should_create_blob_dns_zone
  blob_dns_zone                        = var.blob_dns_zone
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

module "adr_namespace" {
  count = var.should_create_adr_namespace ? 1 : 0

  source = "./modules/adr-namespace"

  location                        = var.location
  resource_group                  = var.resource_group
  adr_namespace_name              = coalesce(var.adr_namespace_name, "adrns-${var.resource_prefix}-${var.environment}-${var.instance}")
  messaging_endpoints             = var.adr_namespace_messaging_endpoints
  enable_system_assigned_identity = var.adr_namespace_enable_identity
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
  is_hns_enabled                          = var.storage_account_is_hns_enabled
}
