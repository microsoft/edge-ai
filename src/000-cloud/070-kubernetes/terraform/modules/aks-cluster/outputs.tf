output "aks" {
  description = "The Azure Kubernetes Service resource created by this module."
  value = {
    id                = azurerm_kubernetes_cluster.aks.id
    name              = azurerm_kubernetes_cluster.aks.name
    default_node_pool = azurerm_kubernetes_cluster.aks.default_node_pool
    dns_prefix        = azurerm_kubernetes_cluster.aks.dns_prefix
  }
}
