/**
 * # Azure Storage Account for Accelerator
 *
 * Create a Storage Account for Accelerator
 *
 */

locals {
  storage_account_name = coalesce(var.storage_account.name, "st${var.resource_prefix}${var.environment}${var.instance}tf")
}

resource "azurerm_storage_account" "store" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group.name
  location                        = var.resource_group.location
  account_tier                    = var.storage_account.tier
  account_replication_type        = var.storage_account.replication_type
  is_hns_enabled                  = false
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
}

resource "azurerm_storage_container" "container" {
  name               = local.storage_account_name
  storage_account_id = azurerm_storage_account.store.id
}
