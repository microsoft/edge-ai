output "aks" {
  description = "The Azure Kubernetes Service resource created by this module."
  value       = length(module.aks_cluster) > 0 ? module.aks_cluster[0].aks : null
}

output "acr" {
  description = "The Azure Container Registry resource created by this module."
  value       = module.container_registry.acr
}
