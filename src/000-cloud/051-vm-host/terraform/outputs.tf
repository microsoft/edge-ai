/*
 * SSH Connection Outputs
 */

output "public_ssh" {
  description = "SSH command to connect to the first VM."
  value       = "ssh -i ../.ssh/vm-${local.label_prefix}-id_rsa ${local.vm_username}@${module.virtual_machine[0].public_fqdn}"
}

output "public_ssh_permissions" {
  description = "File permissions for the SSH private key."
  value       = local_sensitive_file.private_key.file_permission
}

output "ssh_private_key_path" {
  description = "The path to the SSH private key file."
  value       = local_sensitive_file.private_key.filename
}

output "ssh_public_key" {
  description = "The SSH public key for all VMs."
  value       = tls_private_key.ssh.public_key_openssh
}

/*
 * Virtual Machine IP Outputs
 */

output "private_ips" {
  description = "The private IP addresses of all VMs."
  value       = module.virtual_machine[*].private_ip
}

output "public_fqdns" {
  description = "The public FQDNs of all VMs."
  value       = module.virtual_machine[*].public_fqdn
}

output "public_ips" {
  description = "The public IP addresses of all VMs."
  value       = module.virtual_machine[*].public_ip
}

/*
 * Virtual Machine Resource Outputs
 */

output "linux_virtual_machine_name" {
  description = "The names of all Linux virtual machines."
  value       = module.virtual_machine[*].linux_virtual_machine_name
}

output "username" {
  description = "The username for all VMs."
  value       = local.vm_username
}

output "virtual_machines" {
  description = "The created virtual machines."
  value       = module.virtual_machine[*].virtual_machine
}

output "vm_id" {
  description = "The IDs of all VMs."
  value       = module.virtual_machine[*].vm_id
}
