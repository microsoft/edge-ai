output "public_ssh" {
  value = "ssh -i ../.ssh/id_rsa ${local.vm_username}@${azurerm_public_ip.aio_edge.fqdn}"
}

output "public_ip" {
  value = azurerm_public_ip.aio_edge.ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.aio_edge.id
}

