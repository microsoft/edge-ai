/*
 * # Azure Machine Learning Compute Cluster Module
 *
 * This module creates an Azure ML compute cluster for ML training workloads
 */

// Local variables for resource naming following Azure conventions
locals {
  compute_cluster_name = coalesce(var.name, "cluster-${var.resource_prefix}-${var.environment}-${var.instance}")
}

resource "azurerm_machine_learning_compute_cluster" "this" {
  name                          = local.compute_cluster_name
  machine_learning_workspace_id = var.machine_learning_workspace_id
  location                      = var.location
  vm_size                       = var.vm_size
  vm_priority                   = var.vm_priority
  subnet_resource_id            = var.snet_azureml.id
  description                   = var.description
  node_public_ip_enabled        = var.node_public_ip_enabled
  ssh_public_access_enabled     = var.ssh_public_access_enabled

  scale_settings {
    min_node_count                       = var.min_node_count
    max_node_count                       = var.max_node_count
    scale_down_nodes_after_idle_duration = var.scale_down_nodes_after_idle_duration
  }

  identity {
    type = "SystemAssigned"
  }
}
