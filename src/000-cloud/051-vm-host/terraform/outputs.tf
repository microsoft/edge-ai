/*
 * VM Connection Instructions
 */

output "vm_connection_instructions" {
  description = "Connection instructions for VMs with Azure AD authentication and optional fallback methods."
  value = {
    azure_ad_public   = try("az ssh vm -g ${var.resource_group.name} -n ${module.virtual_machine[0].linux_virtual_machine_name}", null)
    azure_ad_private  = try("az ssh vm --ip ${module.virtual_machine[0].private_ip} (requires VPN/ExpressRoute/peered VNet)", null)
    fallback_ssh      = try("ssh -i ../.ssh/vm-${local.label_prefix}-id_rsa ${local.vm_username}@${module.virtual_machine[0].public_fqdn}", null)
    fallback_password = try(random_password.vm_admin[0].result, null)
  }
}

/*
 * Authentication Outputs
 */

output "public_ssh_permissions" {
  description = "File permissions for the SSH private key. Only available when SSH key generation enabled."
  value       = try(local_sensitive_file.private_key[0].file_permission, null)
}

output "ssh_private_key_path" {
  description = "The path to the SSH private key file. Only available when SSH key generation enabled."
  value       = try(local_sensitive_file.private_key[0].filename, null)
}

output "ssh_public_key" {
  description = "The SSH public key for all VMs. Only available when SSH key generation enabled."
  value       = try(tls_private_key.ssh[0].public_key_openssh, null)
  sensitive   = true
}

output "vm_admin_passwords" {
  description = "The generated admin passwords for all VMs. Only available when password authentication is enabled."
  value       = try(random_password.vm_admin[*].result, null)
  sensitive   = true
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
