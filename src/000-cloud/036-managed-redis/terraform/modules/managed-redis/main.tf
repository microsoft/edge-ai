/**
 * # Azure Managed Redis Internal Module
 *
 * Creates Azure Managed Redis cache with optional private endpoint and DNS zone.
 * All variables are required - defaults are provided at component level only.
 */

/*
 * Azure Managed Redis Cache
 */

resource "azurerm_managed_redis" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                  = var.sku_name
  high_availability_enabled = var.should_enable_high_availability

  default_database {
    clustering_policy                  = var.clustering_policy
    access_keys_authentication_enabled = var.access_keys_authentication_enabled
    client_protocol                    = "Encrypted"
  }

  dynamic "identity" {
    for_each = var.managed_identity_id != null || var.customer_managed_key != null ? [1] : []
    content {
      type = "UserAssigned"
      identity_ids = compact([
        var.managed_identity_id,
        var.customer_managed_key != null ? var.customer_managed_key.user_assigned_identity_id : null
      ])
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }
}

/*
 * Private Endpoints
 */

resource "azurerm_private_endpoint" "redis" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_managed_redis.main.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.should_create_private_dns_zone ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
    }
  }

  lifecycle {
    ignore_changes = [
      private_dns_zone_group
    ]
  }
}

/*
 * Private DNS Zones
 */

resource "azurerm_private_dns_zone" "redis" {
  count               = var.should_create_private_dns_zone ? 1 : 0
  name                = "privatelink.redis.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count                 = var.should_create_private_dns_zone ? 1 : 0
  name                  = "vnet-pzl-redis-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "redis" {
  count               = var.should_enable_private_endpoint ? 1 : 0
  name                = var.name
  zone_name           = var.should_create_private_dns_zone ? azurerm_private_dns_zone.redis[0].name : "privatelink.redis.azure.net"
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address]
}
