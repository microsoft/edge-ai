output "container_metrics" {
  description = "The container metrics extension resource."
  value = {
    id   = azurerm_arc_kubernetes_cluster_extension.container_metrics.id
    name = azurerm_arc_kubernetes_cluster_extension.container_metrics.name
  }
}

output "container_logs" {
  description = "The container logs extension resource."
  value = {
    id   = azurerm_arc_kubernetes_cluster_extension.container_logs.id
    name = azurerm_arc_kubernetes_cluster_extension.container_logs.name
  }
}
