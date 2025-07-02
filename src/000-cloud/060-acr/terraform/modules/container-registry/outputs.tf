output "acr" {
  description = "The Azure Container Registry resource created by this module."
  value = {
    id   = azurerm_container_registry.acr.id
    name = azurerm_container_registry.acr.name
    sku  = azurerm_container_registry.acr.sku
  }
}
