/*
 * Network Security Group Outputs
 */

output "network_security_group" {
  description = "The network security group object."
  value = {
    id   = azurerm_network_security_group.main.id
    name = azurerm_network_security_group.main.name
  }
}

/*
 * Virtual Network Outputs
 */

output "subnet_id" {
  description = "The ID of the subnet."
  value       = azurerm_subnet.main.id
}

output "virtual_network" {
  description = "The virtual network object."
  value = {
    id   = azurerm_virtual_network.main.id
    name = azurerm_virtual_network.main.name
  }
}

// DNS and Application Gateway NSG rule outputs removed (relocated to 070-kubernetes)

/*
 * Private Resolver Outputs
 */

output "private_resolver" {
  description = "The Azure Private Resolver configuration and details"
  value       = try(module.private_resolver[0].private_resolver, null)
}

output "dns_server_ip" {
  description = "The IP address of the Private Resolver inbound endpoint to use as DNS server"
  value       = try(module.private_resolver[0].dns_server_ip, null)
}

/*
 * NAT Gateway Outputs
 */

output "nat_gateway" {
  description = "The NAT gateway resource when managed outbound access is enabled"
  value       = try(module.nat_gateway[0].nat_gateway, null)
}

output "nat_gateway_public_ips" {
  description = "Public IP resources associated with the NAT gateway keyed by name"
  value       = try(module.nat_gateway[0].public_ips, {})
}
