/*
 *  Azure ML Outputs
 */

output "azureml_workspace" {
  description = "The Azure ML workspace object when created or discovered."
  value       = module.robotics.azureml_workspace
}

output "nat_gateway" {
  description = "The NAT gateway resource used for managed outbound access when networking is created."
  value       = module.robotics.nat_gateway
}

output "nat_gateway_public_ips" {
  description = "Public IP resources associated with the NAT gateway when managed outbound access is enabled."
  value       = module.robotics.nat_gateway_public_ips
}

output "azureml_edge_extension" {
  description = "The Azure ML edge extension deployment object when deployed."
  value       = module.robotics.azureml_edge_extension
}

output "key_vault" {
  description = "Key Vault object used for the workspace."
  value       = module.robotics.key_vault
}

output "application_insights" {
  description = "Application Insights object used for the workspace."
  value       = module.robotics.application_insights
  sensitive   = true
}

output "aks_cluster" {
  description = "The AKS cluster object when created or discovered for ML integration."
  value       = module.robotics.aks_cluster
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for the AKS cluster when workload identity is enabled."
  value       = module.robotics.aks_oidc_issuer_url
}

output "arc_connected_cluster_id" {
  description = "The Arc connected cluster id when created or discovered for edge ML scenarios."
  value       = module.robotics.arc_connected_cluster_id
}

output "storage_account" {
  description = "Storage Account object used for the workspace."
  value       = module.robotics.storage_account
}

output "acr_network_posture" {
  description = "Azure Container Registry network posture metadata."
  value       = module.robotics.acr_network_posture
}

/*
 * VPN Gateway Outputs
 */

output "vpn_gateway" {
  description = "VPN Gateway configuration when enabled."
  value       = module.robotics.vpn_gateway
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP address for client configuration."
  value       = module.robotics.vpn_gateway_public_ip
}

output "vpn_client_connection_info" {
  description = "VPN client connection information including download URLs."
  value       = module.robotics.vpn_client_connection_info
}

output "private_resolver_dns_ip" {
  description = "Private Resolver DNS IP address for VPN client configuration."
  value       = module.robotics.private_resolver_dns_ip
}

/*
 * VM Host Outputs
 */

output "vm_host_ssh_command" {
  description = "Azure AD SSH command to connect to the first VM host."
  value       = module.robotics.vm_host_ssh_command
}

output "vm_host_public_ips" {
  description = "Public IP addresses of VM hosts."
  value       = module.robotics.vm_host_public_ips
}

output "vm_host_private_ips" {
  description = "Private IP addresses of VM hosts for VPN/internal access."
  value       = module.robotics.vm_host_private_ips
}

output "vm_host_ssh_private_key_path" {
  description = "Path to SSH private key for VM host access."
  value       = module.robotics.vm_host_ssh_private_key_path
  sensitive   = true
}

/*
 * Azure Managed Redis Outputs
 */

output "managed_redis" {
  description = "Azure Managed Redis cache object."
  value       = module.robotics.managed_redis
}

output "managed_redis_connection_info" {
  description = "Azure Managed Redis connection information."
  sensitive   = true
  value       = module.robotics.managed_redis_connection_info
}
