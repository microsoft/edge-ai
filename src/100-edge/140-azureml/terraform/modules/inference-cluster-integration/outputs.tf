output "azureml_extension" {
  description = "The Azure ML extension resource"
  value = {
    id   = azurerm_arc_kubernetes_cluster_extension.azureml.id
    name = azurerm_arc_kubernetes_cluster_extension.azureml.name
  }
}

output "role_assignments" {
  description = "Map of role assignments (may be empty when workspace identity not provided)"
  value = {
    reader                = try(azurerm_role_assignment.reader.id, null)
    extension_contributor = try(azurerm_role_assignment.extension_contributor.id, null)
    cluster_admin         = try(azurerm_role_assignment.cluster_admin.id, null)
    relay_owner           = try(azurerm_role_assignment.relay_owner.id, null)
  }
}

/*
 * Kubernetes Compute Outputs
 */

output "kubernetes_compute" {
  description = "The Kubernetes compute target for Azure ML workspace."
  value       = try(azapi_resource.kubernetes_compute, null)
}

output "compute_target_name" {
  description = "The name of the Kubernetes compute target."
  value       = try(azapi_resource.kubernetes_compute.name, null)
}

output "compute_target_id" {
  description = "The ID of the Kubernetes compute target."
  value       = try(azapi_resource.kubernetes_compute.id, null)
}
