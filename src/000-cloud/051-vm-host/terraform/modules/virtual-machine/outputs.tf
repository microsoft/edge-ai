output "linux_virtual_machine_name" {
  description = "The name of the VM"
  value       = azurerm_linux_virtual_machine.aio_edge.name
}

output "private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_linux_virtual_machine.aio_edge.private_ip_address
}

output "public_fqdn" {
  description = "The public FQDN of the VM"
  value       = try(azurerm_public_ip.aio_edge[0].fqdn, null)
}

output "public_ip" {
  description = "The public IP address of the VM"
  value       = try(azurerm_public_ip.aio_edge[0].ip_address, null)
}

output "virtual_machine" {
  description = "The complete VM resource"
  value = {
    id       = azurerm_linux_virtual_machine.aio_edge.id
    location = azurerm_linux_virtual_machine.aio_edge.location
    name     = azurerm_linux_virtual_machine.aio_edge.name
  }
}

output "vm_id" {
  description = "The ID of the VM"
  value       = azurerm_linux_virtual_machine.aio_edge.id
}
