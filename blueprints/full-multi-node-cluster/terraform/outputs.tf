/*
 * Full Multi Node Cluster Blueprint Outputs
 */

output "container_registry" {
  description = "Azure Container Registry resources."
  value       = module.cloud_acr.acr
}

output "acr_network_posture" {
  description = "Azure Container Registry network posture metadata."
  value       = module.cloud_acr.acr_network_posture
}
