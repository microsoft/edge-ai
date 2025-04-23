output "subnet_id" {
  value       = azurerm_subnet.aio_edge.id
  description = "The ID of the created subnet"
}

output "network_security_group" {
  value = {
    id = azurerm_network_security_group.aio_edge.id
  }
  description = "The created network security group"
}

output "virtual_network" {
  value = {
    id   = azurerm_virtual_network.aio_edge.id
    name = azurerm_virtual_network.aio_edge.name
  }
  description = "The created virtual network"
}
