/*
 * Azure Machine Learning Extension Outputs
 */

output "extension" {
  description = "The Azure ML extension resource for Arc-enabled cluster integration"
  value       = module.inference_cluster_integration.azureml_extension
}

output "role_assignments" {
  description = "Map of role assignments for Arc cluster (may be empty)"
  value       = module.inference_cluster_integration.role_assignments
}

output "kubernetes_compute" {
  description = "Arc Kubernetes compute target (null when not created)"
  value       = module.inference_cluster_integration.kubernetes_compute
}
