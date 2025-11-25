output "storage_account" {
  description = "The newly created Storage Account."
  value = {
    id                     = azurerm_storage_account.storage_account.id
    name                   = azurerm_storage_account.storage_account.name
    primary_blob_endpoint  = azurerm_storage_account.storage_account.primary_blob_endpoint
    primary_file_endpoint  = azurerm_storage_account.storage_account.primary_file_endpoint
    primary_queue_endpoint = azurerm_storage_account.storage_account.primary_queue_endpoint
    primary_table_endpoint = azurerm_storage_account.storage_account.primary_table_endpoint
  }
}

output "private_endpoints" {
  description = "The private endpoint resources for Storage Account."
  value = var.should_enable_private_endpoint ? {
    blob = {
      id                   = azurerm_private_endpoint.storage_blob_pe[0].id
      name                 = azurerm_private_endpoint.storage_blob_pe[0].name
      private_ip_address   = azurerm_private_endpoint.storage_blob_pe[0].private_service_connection[0].private_ip_address
      network_interface_id = azurerm_private_endpoint.storage_blob_pe[0].network_interface[0].id
      custom_dns_configs   = azurerm_private_endpoint.storage_blob_pe[0].custom_dns_configs
    }
    file = {
      id                   = azurerm_private_endpoint.storage_file_pe[0].id
      name                 = azurerm_private_endpoint.storage_file_pe[0].name
      private_ip_address   = azurerm_private_endpoint.storage_file_pe[0].private_service_connection[0].private_ip_address
      network_interface_id = azurerm_private_endpoint.storage_file_pe[0].network_interface[0].id
      custom_dns_configs   = azurerm_private_endpoint.storage_file_pe[0].custom_dns_configs
    }
  } : null
}

output "private_dns_zones" {
  description = "The private DNS zones for Storage Account."
  value = var.should_enable_private_endpoint ? {
    blob = try({
      id   = azurerm_private_dns_zone.blob_dns_zone[0].id
      name = azurerm_private_dns_zone.blob_dns_zone[0].name
    }, null)
    file = try({
      id   = azurerm_private_dns_zone.file_dns_zone[0].id
      name = azurerm_private_dns_zone.file_dns_zone[0].name
    }, null)
  } : null
}
