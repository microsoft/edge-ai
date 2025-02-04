output "public_ssh" {
  value = "ssh -i ../.ssh/id_rsa ${local.vm_username}@${azurerm_public_ip.aio_edge.fqdn}"
}

output "public_ssh_permissions" {
  value = local_sensitive_file.ssh.file_permission
}

output "public_ip" {
  value = azurerm_public_ip.aio_edge.ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.aio_edge.id
}

output "username" {
  value = local.vm_username
}

output "linux_virtual_machine_name" {
  value = azurerm_linux_virtual_machine.aio_edge.name
}

output "virtual_machine" {
  value = azurerm_linux_virtual_machine.aio_edge

  sensitive = true
}
