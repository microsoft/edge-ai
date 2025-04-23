output "snet_acr" {
  description = "The subnet created for Azure Container Registry private endpoint."
  value = try({
    id   = azurerm_subnet.snet_acr[0].id
    name = azurerm_subnet.snet_acr[0].name
  }, null)
}

output "snet_aks" {
  description = "The subnet created for Azure Kubernetes service."
  value = {
    id   = azurerm_subnet.snet_aks.id
    name = azurerm_subnet.snet_aks.name
  }
}

output "snet_aks_pod" {
  description = "The subnet created for Azure Kubernetes service pod vnet."
  value = {
    id   = azurerm_subnet.snet_aks_pod.id
    name = azurerm_subnet.snet_aks_pod.name
  }
}
