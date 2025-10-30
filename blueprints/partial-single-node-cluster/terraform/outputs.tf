/*
 * Resource Group Outputs
 */

output "resource_group" {
  description = "The Azure Resource Group containing all resources."
  value       = module.cloud_resource_group.resource_group
}

/*
 * Security and Identity Outputs
 */

output "key_vault" {
  description = "The Key Vault resource."
  value       = module.cloud_security_identity.key_vault
}

output "arc_onboarding_identity" {
  description = "The identity used for Arc onboarding."
  value       = module.cloud_security_identity.arc_onboarding_identity
}

/*
 * VM Host Outputs
 */

output "vm_connection_instructions" {
  description = "Connection instructions for VMs with Azure AD authentication and optional fallback methods."
  value       = module.cloud_vm_host.vm_connection_instructions
}

/*
 * CNCF Cluster Outputs
 */

output "arc_connected_cluster" {
  description = "The Arc resource for the connected cluster."
  value       = module.edge_cncf_cluster.arc_connected_cluster
}

output "azure_arc_proxy_command" {
  description = "The AZ CLI command to Arc Connect Proxy to the cluster."
  value       = module.edge_cncf_cluster.azure_arc_proxy_command
}
