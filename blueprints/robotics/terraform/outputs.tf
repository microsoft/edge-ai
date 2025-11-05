/*
 * Robotics Blueprint Outputs
 */

output "aks_cluster" {
  description = "AKS cluster for robotics workloads"
  value       = module.robotics.aks_cluster
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.robotics.aks_oidc_issuer_url
}

output "acr_network_posture" {
  description = "Container registry network posture"
  value       = module.robotics.acr_network_posture
}

output "azureml_workspace" {
  description = "Azure ML workspace when AzureML charts are enabled"
  value       = module.robotics.azureml_workspace
}

output "resource_group" {
  description = "Resource group for robotics infrastructure"
  value       = module.robotics.resource_group
}

output "virtual_network" {
  description = "Virtual network for robotics infrastructure"
  value       = module.robotics.virtual_network
}
