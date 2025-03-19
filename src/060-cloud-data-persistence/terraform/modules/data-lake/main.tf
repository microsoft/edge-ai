/**
 * # Data Lake
 *
 * Creates Azure Storage Container, Storage File Share, and a Data Lake Filesystem along with setting up
 * role assignments for provided principal IDs.
 */

resource "azurerm_storage_container" "data_lake" {
  name                  = var.data_lake_blob_container_name
  storage_account_id    = var.storage_account_id
  container_access_type = var.container_access_type
}

# Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake" {
  name               = var.data_lake_filesystem_name
  storage_account_id = var.storage_account_id
}

# File Share (Optional)
resource "azurerm_storage_share" "data_lake" {
  count = var.should_create_data_lake_file_share ? 1 : 0

  name               = var.file_share_name
  quota              = var.file_share_quota_gb
  storage_account_id = var.storage_account_id
}

/*
 * Role Assignments
 */

# Assign Storage Blob Data Owner role to the current user/service principal
resource "azurerm_role_assignment" "data_lake_owner" {
  count = var.data_lake_data_owner_principal_id != null ? 1 : 0

  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.data_lake_data_owner_principal_id
}

resource "azurerm_role_assignment" "data_lake_contributor" {
  count = var.data_lake_data_contributor_principal_id != null ? 1 : 0

  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_lake_data_contributor_principal_id
}
