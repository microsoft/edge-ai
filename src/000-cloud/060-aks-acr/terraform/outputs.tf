output "aks" {
  description = "The Azure Kubernetes Service resource created by this module."
  value       = module.aks_cluster.aks
}

output "acr" {
  description = "The Azure Container Registry resource created by this module."
  value       = module.container_registry.acr
}
