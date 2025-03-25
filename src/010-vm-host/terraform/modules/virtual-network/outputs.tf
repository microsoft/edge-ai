output "subnet_id" {
  value       = azurerm_subnet.aio_edge.id
  description = "The ID of the created subnet"
}

output "network_security_group_id" {
  value       = azurerm_network_security_group.aio_edge.id
  description = "The ID of the created network security group"
}