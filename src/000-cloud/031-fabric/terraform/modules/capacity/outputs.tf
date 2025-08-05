output "capacity" {
  description = "The Fabric capacity."
  value = {
    id           = azurerm_fabric_capacity.this.id
    display_name = azurerm_fabric_capacity.this.name
    sku          = azurerm_fabric_capacity.this.sku[0].name
  }
}
