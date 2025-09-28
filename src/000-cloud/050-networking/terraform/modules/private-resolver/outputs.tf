/*
 * Private Resolver Outputs
 */

output "private_resolver" {
  description = "The Azure Private Resolver resource"
  value = {
    id   = azurerm_private_dns_resolver.main.id
    name = azurerm_private_dns_resolver.main.name
  }
}

output "inbound_endpoint" {
  description = "The inbound endpoint for DNS resolution"
  value = {
    id         = azurerm_private_dns_resolver_inbound_endpoint.main.id
    name       = azurerm_private_dns_resolver_inbound_endpoint.main.name
    ip_address = azurerm_private_dns_resolver_inbound_endpoint.main.ip_configurations[0].private_ip_address
    subnet_id  = azurerm_private_dns_resolver_inbound_endpoint.main.ip_configurations[0].subnet_id
  }
}

output "resolver_subnet" {
  description = "The subnet created for the Private Resolver"
  value = {
    id               = azurerm_subnet.resolver_subnet.id
    name             = azurerm_subnet.resolver_subnet.name
    address_prefixes = azurerm_subnet.resolver_subnet.address_prefixes
  }
}

output "dns_server_ip" {
  description = "The IP address to use as DNS server for VNet configuration"
  value       = azurerm_private_dns_resolver_inbound_endpoint.main.ip_configurations[0].private_ip_address
}
