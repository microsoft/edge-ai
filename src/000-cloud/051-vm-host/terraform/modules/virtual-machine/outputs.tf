output "public_ip" {
  value       = azurerm_public_ip.aio_edge.ip_address
  description = "The public IP address of the VM"
}

output "private_ip" {
  value       = azurerm_linux_virtual_machine.aio_edge.private_ip_address
  description = "The private IP address of the VM"
}

output "public_fqdn" {
  value       = azurerm_public_ip.aio_edge.fqdn
  description = "The public FQDN of the VM"
}

output "vm_id" {
  value       = azurerm_linux_virtual_machine.aio_edge.id
  description = "The ID of the VM"
}

output "virtual_machine" {
  value = {
    id       = azurerm_linux_virtual_machine.aio_edge.id
    name     = azurerm_linux_virtual_machine.aio_edge.name
    location = azurerm_linux_virtual_machine.aio_edge.location
  }
  description = "The complete VM resource"
}

output "linux_virtual_machine_name" {
  value       = azurerm_linux_virtual_machine.aio_edge.name
  description = "The name of the VM"
}
