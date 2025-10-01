output "aks" {
  description = "The AKS cluster."
  value       = try(module.aks_cluster[0].aks, null)
}

output "aks_identity" {
  description = "The AKS identity."
  value       = try(module.aks_cluster[0].aks_identity, null)
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for the AKS cluster."
  value       = try(module.aks_cluster[0].aks.oidc_issuer_url, null)
}

output "aks_kube_config" {
  description = "The AKS cluster."
  value       = try(module.aks_cluster[0].aks_kube_config, null)
  sensitive   = true
}

output "aks_node_pools" {
  description = "The node pools of the AKS cluster."
  value       = try(module.aks_cluster[0].node_pools, null)
}

output "aks_private_endpoint" {
  description = "The private endpoint of the AKS cluster."
  value       = try(module.aks_cluster[0].private_endpoint, null)
}

output "aks_private_dns_zone" {
  description = "The private DNS zone of the AKS cluster."
  value       = try(module.aks_cluster[0].private_dns_zone, null)
}

output "connected_cluster_name" {
  description = "The name of the Azure Arc Cluster Instance resource."
  value       = try(module.arc_cluster_instance[0].connected_cluster_name, null)
}

output "connected_cluster_id" {
  description = "The ID of the Azure Arc Cluster Instance resource."
  value       = try(module.arc_cluster_instance[0].connected_cluster_id, null)
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the Azure Arc Cluster Instance."
  value       = try(module.arc_cluster_instance[0].oidc_issuer_url, null)
}

output "private_key_pem" {
  description = "The private key PEM for the Azure Arc Cluster Instance."
  value       = try(module.arc_cluster_instance[0].private_key_pem, null)
  sensitive   = true
}


/*
 * NAT Gateway Outputs
 */

/*
 * AKS Command Invoke Outputs
 */

output "aks_command_invoke_results" {
  description = "Map of command invoke execution results by configuration name."
  value = {
    for name, cmd in module.command_invoke : name => {
      id        = cmd.id
      exit_code = cmd.exit_code
      logs      = cmd.logs
      success   = cmd.success
    }
  }
}
