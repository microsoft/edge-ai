/**
 * # Azure Storage Account
 *
 * Create a new Azure Storage Account with the specified configuration.
 */

locals {
  storage_account_name = substr(lower("st${random_string.random_clean_prefix.result}${replace(var.resource_prefix, "-", "")}${replace(var.environment, "-", "")}${var.instance}"), 0, 24)
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
  is_hns_enabled                  = var.is_hns_enabled
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.should_enable_public_network_access

  dynamic "blob_properties" {
    for_each = var.is_hns_enabled ? [] : [1]
    content {
      delete_retention_policy {
        days = var.blob_soft_delete_retention_days
      }
      container_delete_retention_policy {
        days = var.container_soft_delete_retention_days
      }
    }
  }
}

/*
 * Private Endpoints
 */

resource "azurerm_private_endpoint" "storage_blob_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-blob-${azurerm_storage_account.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-blob-privatelink"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.blob_dns_zone != null ? [1] : []
    content {
      name                 = "blob-dns-zone-group"
      private_dns_zone_ids = [var.blob_dns_zone.id]
    }
  }
}

resource "azurerm_private_endpoint" "storage_file_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-file-${azurerm_storage_account.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-file-privatelink"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}

resource "azurerm_private_endpoint" "storage_dfs_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-dfs-${azurerm_storage_account.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-dfs-privatelink"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }
}

resource "azurerm_private_dns_zone" "blob_dns_zone" {
  count = alltrue([var.should_enable_private_endpoint, var.should_create_blob_dns_zone]) ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone" "file_dns_zone" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone" "dfs_dns_zone" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_vnet_link" {
  count = alltrue([var.should_enable_private_endpoint, var.should_create_blob_dns_zone]) ? 1 : 0

  name                  = "vnet-pzl-blob-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns_zone[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_vnet_link" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                  = "vnet-pzl-file-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.file_dns_zone[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "dfs_vnet_link" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                  = "vnet-pzl-dfs-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dfs_dns_zone[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "blob_a_record" {
  count = alltrue([var.should_enable_private_endpoint, var.should_create_blob_dns_zone]) ? 1 : 0

  name                = azurerm_storage_account.storage_account.name
  zone_name           = try(azurerm_private_dns_zone.blob_dns_zone[0].name, var.blob_dns_zone.name, null)
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_blob_pe[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "file_a_record" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = azurerm_storage_account.storage_account.name
  zone_name           = azurerm_private_dns_zone.file_dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_file_pe[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "dfs_a_record" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = azurerm_storage_account.storage_account.name
  zone_name           = azurerm_private_dns_zone.dfs_dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_dfs_pe[0].private_service_connection[0].private_ip_address]
}
