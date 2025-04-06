output "resource_group" {
  value = {
    id       = azurerm_resource_group.new.id
    name     = azurerm_resource_group.new.name
    location = azurerm_resource_group.new.location
  }
}
