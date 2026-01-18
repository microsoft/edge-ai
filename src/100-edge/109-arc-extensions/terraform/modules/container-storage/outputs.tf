output "container_storage" {
  description = "Self-contained container_storage object"
  value = {
    enabled = var.container_storage_extension.enabled
    id      = azurerm_arc_kubernetes_cluster_extension.container_storage.id
    name    = azurerm_arc_kubernetes_cluster_extension.container_storage.name
    version = var.container_storage_extension.version
    train   = var.container_storage_extension.train
  }
}

output "extension" {
  description = "The container storage extension id and name as an object"
  value = {
    id   = azurerm_arc_kubernetes_cluster_extension.container_storage.id
    name = azurerm_arc_kubernetes_cluster_extension.container_storage.name
  }
}
