output "acr" {
  description = "The Azure Container Registry resource created by this module."
  value = {
    id   = azurerm_container_registry.acr.id
    name = azurerm_container_registry.acr.name
    sku  = azurerm_container_registry.acr.sku
  }
}

output "private_endpoint" {
  description = "The private endpoint resource for Azure Container Registry."
  value = var.should_create_acr_private_endpoint ? {
    id                   = azurerm_private_endpoint.pep[0].id
    name                 = azurerm_private_endpoint.pep[0].name
    private_ip_address   = azurerm_private_endpoint.pep[0].private_service_connection[0].private_ip_address
    network_interface_id = azurerm_private_endpoint.pep[0].network_interface[0].id
    custom_dns_configs   = azurerm_private_endpoint.pep[0].custom_dns_configs
  } : null
}

output "private_dns_zone" {
  description = "The private DNS zone for Azure Container Registry."
  value = var.should_create_acr_private_endpoint ? {
    id   = azurerm_private_dns_zone.dns_zone[0].id
    name = azurerm_private_dns_zone.dns_zone[0].name
  } : null
}
