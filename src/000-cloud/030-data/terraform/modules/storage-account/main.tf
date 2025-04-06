/**
 * # Azure Storage Account
 *
 * Create a new Azure Storage Account with the specified configuration.
 */

locals {
  storage_account_name = substr(lower("st${random_string.random_clean_prefix.result}${var.environment}aio${var.instance}"), 0, 24)
}

/*
 * Storage Account
 */

resource "random_string" "random_clean_prefix" {
  length  = 5
  special = false
  upper   = false
  lower   = true
  numeric = true
}

resource "azurerm_storage_account" "storage_account" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group.name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  min_tls_version                 = "TLS1_2"
  is_hns_enabled                  = true
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }
}

/*
 * Private Endpoint
 */

resource "azurerm_private_endpoint" "storage_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pep-${var.resource_prefix}-${var.environment}-storage-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.resource_prefix}-${var.environment}-storage-${var.instance}"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob", "file"]
  }
}
