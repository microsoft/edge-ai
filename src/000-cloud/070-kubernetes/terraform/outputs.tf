output "aks" {
  description = "The Azure Kubernetes Service resource created by this module."
  value       = length(module.aks_cluster) > 0 ? module.aks_cluster[0].aks : null
}

output "connected_cluster_name" {
  description = "The name of the Azure Arc Cluster Instance resource."
  value       = length(module.arc_cluster_instance) > 0 ? module.arc_cluster_instance[0].connected_cluster_name : null
}

output "connected_cluster_id" {
  description = "The ID of the Azure Arc Cluster Instance resource."
  value       = length(module.arc_cluster_instance) > 0 ? module.arc_cluster_instance[0].connected_cluster_id : null
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the Azure Arc Cluster Instance."
  value       = length(module.arc_cluster_instance) > 0 ? module.arc_cluster_instance[0].oidc_issuer_url : null
}

output "private_key_pem" {
  description = "The private key PEM for the Azure Arc Cluster Instance."
  value       = length(module.arc_cluster_instance) > 0 ? module.arc_cluster_instance[0].private_key_pem : null
}
