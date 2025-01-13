output "platform_cluster_extension_id" {
  value = azurerm_arc_kubernetes_cluster_extension.platform.id
}

output "secret_store_extension_cluster_id" {
  value = azurerm_arc_kubernetes_cluster_extension.secret_store.id
}
