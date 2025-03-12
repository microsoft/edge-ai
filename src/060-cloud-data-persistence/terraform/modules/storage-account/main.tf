/**
 * # Azure Storage Account
 *
 * Create a new Azure Storage Account with the specified configuration.
 */

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  min_tls_version          = "TLS1_2"
  is_hns_enabled           = true

  blob_properties {
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  tags = var.tags
}

# Private Endpoint (Optional)
resource "azurerm_private_endpoint" "storage_pe" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pep-${var.resource_prefix}-${var.environment}-storage-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-${var.resource_prefix}-${var.environment}-storage-${var.instance}"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob", "file"]
  }

  tags = var.tags
}