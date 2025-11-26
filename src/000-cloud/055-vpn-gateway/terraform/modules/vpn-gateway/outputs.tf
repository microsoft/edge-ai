output "vpn_gateway" {
  description = "The VPN Gateway resource"
  value = {
    id           = azurerm_virtual_network_gateway.vpn.id
    name         = azurerm_virtual_network_gateway.vpn.name
    gateway_type = azurerm_virtual_network_gateway.vpn.type
    vpn_type     = azurerm_virtual_network_gateway.vpn.vpn_type
    sku          = azurerm_virtual_network_gateway.vpn.sku
    generation   = azurerm_virtual_network_gateway.vpn.generation
    client_config = {
      address_space = var.vpn_gateway_config.client_address_pool
      protocols     = var.vpn_gateway_config.protocols
    }
  }
}

output "public_ip_address" {
  description = "The public IP address of the VPN Gateway"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "gateway_subnet" {
  description = "The Gateway subnet information"
  value = {
    id             = azurerm_subnet.gateway_subnet.id
    name           = azurerm_subnet.gateway_subnet.name
    address_prefix = azurerm_subnet.gateway_subnet.address_prefixes[0]
  }
}


