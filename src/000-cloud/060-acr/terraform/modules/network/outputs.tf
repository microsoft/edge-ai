output "snet_acr" {
  description = "The subnet created for Azure Container Registry private endpoint."
  value = try({
    id   = azurerm_subnet.snet_acr[0].id
    name = azurerm_subnet.snet_acr[0].name
  }, null)
}
