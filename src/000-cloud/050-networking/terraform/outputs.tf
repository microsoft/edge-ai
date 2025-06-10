/*
 * Network Security Group Outputs
 */

output "network_security_group" {
  description = "The network security group object."
  value = {
    id = azurerm_network_security_group.main.id
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
