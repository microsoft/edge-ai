output "cert_manager" {
  description = "Self-contained cert-manager object"
  value = {
    enabled = var.cert_manager_extension.enabled
    id      = azurerm_arc_kubernetes_cluster_extension.cert_manager.id
    name    = azurerm_arc_kubernetes_cluster_extension.cert_manager.name
    version = var.cert_manager_extension.version
    train   = var.cert_manager_extension.train
  }
}

output "extension" {
  description = "The cert-manager extension id and name as an object"
  value = {
    id   = azurerm_arc_kubernetes_cluster_extension.cert_manager.id
    name = azurerm_arc_kubernetes_cluster_extension.cert_manager.name
  }
}
