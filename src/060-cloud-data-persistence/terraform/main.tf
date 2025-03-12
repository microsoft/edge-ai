# Azure Storage Account and Container Terraform Configuration

locals {
  # Define tags here with individual variables
  tags = {
    Environment = var.environment
    Instance    = var.instance
    component   = "storage"
  }

  # Storage account name
  storage_account_name = substr(lower("st${random_string.random_clean_prefix.result}${var.environment}aio${var.instance}"), 0, 24)
}

# Generate random string for storage account name
resource "random_string" "random_clean_prefix" {
  length  = 5
  special = false
  upper   = false
  lower   = true
  numeric = true
}

# Call the data-lake module and pass the storage account details
module "data_lake" {
  source = "./modules/data-lake"

  container_name                = var.container_name
  storage_account_id            = module.storage_account.id
  container_access_type         = var.container_access_type
  managed_identity_principal_id = var.managed_identity_principal_id != null ? var.managed_identity_principal_id : ""
  create_file_share             = var.create_file_share
  file_share_name               = var.file_share_name
  file_share_quota_gb           = var.file_share_quota_gb
  data_lake_filesystem_name     = var.data_lake_filesystem_name
}

# Storage Account
module "storage_account" {
  source = "./modules/storage-account"

  storage_account_name                 = local.storage_account_name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  account_tier                         = var.storage_account_tier
  account_replication_type             = var.storage_account_replication
  account_kind                         = var.storage_account_kind
  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  tags                                 = local.tags
  environment                          = var.environment
  instance                             = var.instance
  resource_prefix                      = var.resource_prefix
  subnet_id                            = var.subnet_id
  enable_private_endpoint              = var.enable_private_endpoint
}
