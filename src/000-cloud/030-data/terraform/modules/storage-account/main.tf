/**
 * # Azure Storage Account
 *
 * Create a new Azure Storage Account with the specified configuration.
 */

locals {
  storage_account_name = substr(lower("st${random_string.random_clean_prefix.result}${replace(var.resource_prefix, "-", "")}${replace(var.environment, "-", "")}${var.instance}"), 0, 24)
  // Selects the storage-account creation path. Network Security Perimeter association is only
  // available on the control-plane (azapi) resource, so enabling it switches from
  // azurerm_storage_account to azapi_resource.storage_account.
  //
  // WARNING: toggling should_use_network_security_perimeter on an EXISTING deployment moves the
  // account between two different resource addresses (azurerm_storage_account.storage_account ->
  // azapi_resource.storage_account). Terraform plans this as destroy-then-create (data loss and a
  // likely name collision); a `moved` block cannot bridge different resource types. Migrate an
  // existing account with `terraform state rm` + `terraform import` per the runbook in the
  // component README (030-data), never by applying the flag flip directly.
  should_use_azapi_storage_account = var.should_use_network_security_perimeter
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
  count = local.should_use_azapi_storage_account ? 0 : 1

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

resource "azapi_resource" "storage_account" {
  count = local.should_use_azapi_storage_account ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts@2024-01-01"
  name      = local.storage_account_name
  parent_id = var.resource_group.id
  location  = var.location

  body = {
    kind = var.account_kind
    sku = {
      name = "${var.account_tier}_${var.account_replication_type}"
    }
    properties = merge({
      allowBlobPublicAccess    = false
      allowSharedKeyAccess     = false
      isHnsEnabled             = var.is_hns_enabled
      minimumTlsVersion        = "TLS1_2"
      publicNetworkAccess      = var.should_enable_public_network_access ? "Enabled" : "Disabled"
      supportsHttpsTrafficOnly = true
      }, contains(["BlobStorage", "StorageV2"], var.account_kind) ? {
      accessTier = "Hot"
    } : {})
  }

  response_export_values = ["properties.primaryEndpoints"]
}

resource "azapi_resource" "blob_service" {
  count = local.should_use_azapi_storage_account && !var.is_hns_enabled ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts/blobServices@2024-01-01"
  name      = "default"
  parent_id = azapi_resource.storage_account[0].id

  body = {
    properties = {
      containerDeleteRetentionPolicy = {
        enabled = true
        days    = var.container_soft_delete_retention_days
      }
      deleteRetentionPolicy = {
        enabled = true
        days    = var.blob_soft_delete_retention_days
      }
    }
  }
}

locals {
  storage_account = local.should_use_azapi_storage_account ? {
    id                     = azapi_resource.storage_account[0].id
    name                   = azapi_resource.storage_account[0].name
    primary_blob_endpoint  = azapi_resource.storage_account[0].output.properties.primaryEndpoints.blob
    primary_file_endpoint  = azapi_resource.storage_account[0].output.properties.primaryEndpoints.file
    primary_queue_endpoint = azapi_resource.storage_account[0].output.properties.primaryEndpoints.queue
    primary_table_endpoint = azapi_resource.storage_account[0].output.properties.primaryEndpoints.table
    } : {
    id                     = azurerm_storage_account.storage_account[0].id
    name                   = azurerm_storage_account.storage_account[0].name
    primary_blob_endpoint  = azurerm_storage_account.storage_account[0].primary_blob_endpoint
    primary_file_endpoint  = azurerm_storage_account.storage_account[0].primary_file_endpoint
    primary_queue_endpoint = azurerm_storage_account.storage_account[0].primary_queue_endpoint
    primary_table_endpoint = azurerm_storage_account.storage_account[0].primary_table_endpoint
  }
}

resource "azapi_resource" "network_security_perimeter_association" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  type      = "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-01-01"
  name      = "storage-${local.storage_account.name}"
  parent_id = var.network_security_perimeter_id

  body = {
    properties = {
      accessMode = "Enforced"
      privateLinkResource = {
        id = local.storage_account.id
      }
      profile = {
        id = var.network_security_perimeter_profile_id
      }
    }
  }
}

resource "time_sleep" "network_security_perimeter_propagation" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  create_duration = var.network_security_perimeter_propagation_delay
  triggers = {
    network_security_perimeter = var.network_security_perimeter_propagation_trigger
  }

  depends_on = [azapi_resource.network_security_perimeter_association]
}

resource "terraform_data" "defer" {
  input = {
    id                     = local.storage_account.id
    name                   = local.storage_account.name
    primary_blob_endpoint  = local.storage_account.primary_blob_endpoint
    primary_file_endpoint  = local.storage_account.primary_file_endpoint
    primary_queue_endpoint = local.storage_account.primary_queue_endpoint
    primary_table_endpoint = local.storage_account.primary_table_endpoint
  }

  depends_on = [time_sleep.network_security_perimeter_propagation]
}

/*
 * Private Endpoints
 */

resource "azurerm_private_endpoint" "storage_blob_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-blob-${local.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-blob-privatelink"
    private_connection_resource_id = local.storage_account.id
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
  name                = "pe-file-${local.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-file-privatelink"
    private_connection_resource_id = local.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}

resource "azurerm_private_endpoint" "storage_dfs_pe" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-dfs-${local.storage_account.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-dfs-privatelink"
    private_connection_resource_id = local.storage_account.id
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

  name                = local.storage_account.name
  zone_name           = try(azurerm_private_dns_zone.blob_dns_zone[0].name, var.blob_dns_zone.name, null)
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_blob_pe[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "file_a_record" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = local.storage_account.name
  zone_name           = azurerm_private_dns_zone.file_dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_file_pe[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "dfs_a_record" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = local.storage_account.name
  zone_name           = azurerm_private_dns_zone.dfs_dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_dfs_pe[0].private_service_connection[0].private_ip_address]
}
