output "public_ssh" {
  value = "ssh -i ../.ssh/vm-${local.label_prefix}-id_rsa ${local.vm_username}@${azurerm_public_ip.aio_edge[0].fqdn}"
}

output "public_ssh_permissions" {
  value = local_sensitive_file.ssh.file_permission
}

output "public_ips" {
  value = azurerm_public_ip.aio_edge[*].ip_address
}

output "private_ips" {
  value = azurerm_linux_virtual_machine.aio_edge[*].private_ip_address
}

output "public_fqdns" {
  value = azurerm_public_ip.aio_edge[*].fqdn
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.aio_edge[*].id
}

output "username" {
  value = local.vm_username
}

output "linux_virtual_machine_name" {
  value = azurerm_linux_virtual_machine.aio_edge[*].name
}

output "virtual_machines" {
  value = azurerm_linux_virtual_machine.aio_edge[*]

  sensitive = true
}
