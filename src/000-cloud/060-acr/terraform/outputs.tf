output "acr" {
  description = "The Azure Container Registry resource created by this module."
  value       = module.container_registry.acr
}
