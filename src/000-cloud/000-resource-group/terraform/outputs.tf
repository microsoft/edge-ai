output "resource_group" {
  value = {
    id       = local.rg_exists ? data.azurerm_resource_group.existing[0].id : try(azurerm_resource_group.new[0].id, null)
    name     = local.resource_group_name
    location = local.rg_exists ? data.azurerm_resource_group.existing[0].location : try(azurerm_resource_group.new[0].location, null)
  }
}
