/* Structured Outputs */

output "connection_info" {
  description = "Redis connection information."
  value = {
    hostname   = azurerm_managed_redis.main.hostname
    port       = azurerm_managed_redis.main.default_database[0].port
    ssl        = true
    auth_type  = var.access_keys_authentication_enabled ? "access_keys" : "entra_id"
    private_ip = var.should_enable_private_endpoint ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
  }
  sensitive = true
}

output "managed_redis" {
  description = "Azure Managed Redis cache details."
  value = {
    hostname            = azurerm_managed_redis.main.hostname
    id                  = azurerm_managed_redis.main.id
    location            = azurerm_managed_redis.main.location
    name                = azurerm_managed_redis.main.name
    resource_group_name = azurerm_managed_redis.main.resource_group_name
    sku_name            = azurerm_managed_redis.main.sku_name
    port                = azurerm_managed_redis.main.default_database[0].port
  }
}

output "private_endpoint" {
  description = "Private endpoint details when enabled."
  value = var.should_enable_private_endpoint ? {
    custom_dns_configs   = azurerm_private_endpoint.redis[0].custom_dns_configs
    id                   = azurerm_private_endpoint.redis[0].id
    name                 = azurerm_private_endpoint.redis[0].name
    network_interface_id = azurerm_private_endpoint.redis[0].network_interface[0].id
    private_ip_address   = azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address
  } : null
}
