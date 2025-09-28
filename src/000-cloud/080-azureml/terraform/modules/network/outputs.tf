output "snet_azureml" {
  description = "The subnet created for Azure ML compute cluster."
  value = {
    id   = azurerm_subnet.snet_azureml.id
    name = azurerm_subnet.snet_azureml.name
  }
}
