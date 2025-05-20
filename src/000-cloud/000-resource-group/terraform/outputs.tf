output "resource_group" {
  value = {
    id       = var.use_existing_resource_group ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.new[0].id
    name     = local.resource_group_name
    location = var.use_existing_resource_group ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.new[0].location
  }
}
