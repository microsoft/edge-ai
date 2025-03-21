output "vnet" {
  value = azurerm_virtual_network.vnet
}

output "snet_kv" {
  value = azurerm_subnet.snet_kv
}

output "snet_pool" {
  value = azurerm_subnet.snet_pool
}