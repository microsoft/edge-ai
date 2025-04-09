output "vnet" {
  description = "The virtual network created by this module."
  value       = azurerm_virtual_network.vnet
}

output "snet_kv" {
  description = "The subnet created for Key Vault private endpoint."
  value       = azurerm_subnet.snet_kv
}

output "snet_pool" {
  description = "The subnet created for DevOps agent pool."
  value       = azurerm_subnet.snet_pool
}

output "snet_acr" {
  description = "The subnet created for Azure Container Registry private endpoint."
  value       = azurerm_subnet.snet_acr
}
