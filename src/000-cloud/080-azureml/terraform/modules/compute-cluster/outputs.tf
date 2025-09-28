/*
 * Compute Cluster Outputs
 */

output "compute_cluster" {
  description = "Azure Machine Learning compute cluster object."
  value = {
    id                            = azurerm_machine_learning_compute_cluster.this.id
    name                          = azurerm_machine_learning_compute_cluster.this.name
    location                      = azurerm_machine_learning_compute_cluster.this.location
    machine_learning_workspace_id = azurerm_machine_learning_compute_cluster.this.machine_learning_workspace_id
  }
}

output "compute_cluster_id" {
  description = "The ID of the compute cluster."
  value       = azurerm_machine_learning_compute_cluster.this.id
}

output "compute_cluster_name" {
  description = "The name of the compute cluster."
  value       = azurerm_machine_learning_compute_cluster.this.name
}

output "principal_id" {
  description = "The Principal ID of the System Assigned Managed Service Identity."
  value       = azurerm_machine_learning_compute_cluster.this.identity[0].principal_id
}

output "tenant_id" {
  description = "The Tenant ID of the System Assigned Managed Service Identity."
  value       = azurerm_machine_learning_compute_cluster.this.identity[0].tenant_id
}
