/**
 * # Azure Storage Container
 *
 * Create a new Azure Storage Container with the specified configuration.
 */

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_id    = var.storage_account_id
  container_access_type = var.container_access_type
}

# Assign Storage Blob Data Owner role to the current user/service principal
resource "azurerm_role_assignment" "data_lake_owner" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# If using a User-Assigned Managed Identity, assign it Storage Blob Data Contributor role
resource "azurerm_role_assignment" "data_lake_contributor" {
  count                = var.managed_identity_principal_id != "" ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}

# File Share (Optional)
resource "azurerm_storage_share" "file_share" {
  count              = var.create_file_share ? 1 : 0
  name               = var.file_share_name
  quota              = var.file_share_quota_gb
  storage_account_id = var.storage_account_id
}

# Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake" {
  name               = var.data_lake_filesystem_name
  storage_account_id = var.storage_account_id
}

# Add data source for current client config
data "azurerm_client_config" "current" {}