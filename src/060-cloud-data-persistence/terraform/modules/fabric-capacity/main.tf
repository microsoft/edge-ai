# Resource for creating a Fabric capacity using azurerm provider
resource "azurerm_fabric_capacity" "this" {
  count = var.create_capacity ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku {
    name = var.sku
    tier = "Fabric"
  }

  administration_members = var.admin_members

  tags = var.tags
}