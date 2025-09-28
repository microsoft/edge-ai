output "key_vault" {
  value = terraform_data.defer.output.key_vault
}

output "private_endpoint" {
  description = "The private endpoint resource for Key Vault."
  value = var.should_create_private_endpoint ? {
    id                   = azurerm_private_endpoint.key_vault[0].id
    name                 = azurerm_private_endpoint.key_vault[0].name
    private_ip_address   = azurerm_private_endpoint.key_vault[0].private_service_connection[0].private_ip_address
    network_interface_id = azurerm_private_endpoint.key_vault[0].network_interface[0].id
    custom_dns_configs   = azurerm_private_endpoint.key_vault[0].custom_dns_configs
  } : null
}

output "private_dns_zone" {
  description = "The private DNS zone for Key Vault."
  value = var.should_create_private_endpoint ? {
    id   = azurerm_private_dns_zone.dns_zone[0].id
    name = azurerm_private_dns_zone.dns_zone[0].name
  } : null
}
