output "public_ssh" {
  value = "ssh -i ../.ssh/vm-${local.label_prefix}-id_rsa ${local.vm_username}@${module.virtual_machine[0].public_fqdn}"
}

output "public_ssh_permissions" {
  value = local_sensitive_file.private_key.file_permission
}

output "ssh_private_key_path" {
  value       = local_sensitive_file.private_key.filename
  description = "The path to the SSH private key file"
}

output "ssh_public_key" {
  value       = tls_private_key.ssh.public_key_openssh
  description = "The SSH public key for all VMs"
}

output "public_ips" {
  value = module.virtual_machine[*].public_ip
}

output "private_ips" {
  value = module.virtual_machine[*].private_ip
}

output "public_fqdns" {
  value = module.virtual_machine[*].public_fqdn
}

output "vm_id" {
  value = module.virtual_machine[*].vm_id
}

output "username" {
  value = local.vm_username
}

output "linux_virtual_machine_name" {
  value = module.virtual_machine[*].linux_virtual_machine_name
}

output "virtual_machines" {
  value     = module.virtual_machine[*].virtual_machine
  sensitive = true
}

output "network_security_group" {
  value       = module.virtual_network.network_security_group
  description = "The created network security group"
}

output "virtual_network" {
  value       = module.virtual_network.virtual_network
  description = "The created virtual network"
}
