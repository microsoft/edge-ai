/*
 * Azure Machine Learning Workspace Outputs
 */

output "azureml_workspace" {
  description = "The Azure Machine Learning workspace object."
  value       = module.workspace.workspace
}

output "workspace_id" {
  description = "The immutable resource ID of the workspace."
  value       = module.workspace.workspace_id
}

output "workspace_name" {
  description = "The name of the workspace."
  value       = module.workspace.workspace_name
}

output "workspace_principal_id" {
  description = "The Principal ID of the workspace System Assigned Managed Service Identity."
  value       = module.workspace.principal_id
}

output "workspace_private_endpoint" {
  description = "The private endpoint resource for Azure ML workspace."
  value       = module.workspace.private_endpoint
}

output "workspace_private_dns_zones" {
  description = "The private DNS zones for Azure ML workspace."
  value       = module.workspace.private_dns_zones
}

/*
 * Registry Outputs
 */

output "registry" {
  description = "AzureML Registry information."
  value = var.should_deploy_registry ? {
    id               = module.registry[0].registry.id
    name             = module.registry[0].registry.name
    discovery_url    = module.registry[0].registry_discovery_url
    private_endpoint = module.registry[0].private_endpoint
  } : null
}

/*
 * Compute Cluster Outputs
 */

output "compute_cluster" {
  description = "The Azure Machine Learning compute cluster object."
  value       = try(module.compute_cluster[0].compute_cluster, null)
}

output "compute_cluster_id" {
  description = "The ID of the compute cluster."
  value       = try(module.compute_cluster[0].compute_cluster_id, null)
}

output "compute_cluster_name" {
  description = "The name of the compute cluster."
  value       = try(module.compute_cluster[0].compute_cluster_name, null)
}

output "compute_cluster_principal_id" {
  description = "The Principal ID of the compute cluster System Assigned Managed Service Identity."
  value       = try(module.compute_cluster[0].principal_id, null)
}

/*
 * AKS Integration Outputs
 */

output "azureml_extension" {
  description = "The Azure ML extension resource."
  value       = try(module.inference_cluster_integration[0].azureml_extension, null)
}

output "kubernetes_compute" {
  description = "The Azure ML Kubernetes compute resource."
  value       = try(module.inference_cluster_integration[0].kubernetes_compute, null)
}

output "ml_workload_identity" {
  description = "The AzureML workload managed identity passed into the component."
  value       = var.ml_workload_identity
}
