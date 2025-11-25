resource "terraform_data" "defer" {
  input = {
    resource_group_name   = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    fabric_capacity_name  = var.fabric_capacity_name
    fabric_workspace_name = var.fabric_workspace_name
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source          = "../../terraform"
  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance
  resource_group  = data.azurerm_resource_group.aio
  location        = data.azurerm_resource_group.aio.location

  // Resource names using terraform_data defer outputs
  fabric_capacity_name   = terraform_data.defer.output.fabric_capacity_name
  fabric_workspace_name  = terraform_data.defer.output.fabric_workspace_name
  fabric_capacity_admins = var.fabric_capacity_admins

  // Resource creation flags
  should_create_fabric_capacity   = var.should_create_fabric_capacity
  should_create_fabric_workspace  = var.should_create_fabric_workspace
  should_create_fabric_lakehouse  = var.should_create_fabric_lakehouse
  should_create_fabric_eventhouse = var.should_create_fabric_eventhouse
}
