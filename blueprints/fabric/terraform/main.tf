/**
 * # Fabric Blueprint
 *
 * Deploys Microsoft Fabric capacity, workspace, lakehouse, and eventhouse resources.
 */

locals {
  fabric_capacity_admins = length(var.fabric_capacity_admins_list) > 0 ? (
    var.fabric_capacity_admins_list
    ) : (
    [msgraph_resource_action.current_user[0].output.upn]
  )
}

/*
 * Current User Data (Microsoft Graph)
 */

resource "msgraph_resource_action" "current_user" {
  count = length(var.fabric_capacity_admins_list) == 0 ? 1 : 0

  method       = "GET"
  resource_url = "me"

  response_export_values = {
    upn = "userPrincipalName"
  }
}

resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(var.resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")
  }
}

data "azurerm_resource_group" "existing" {
  name = terraform_data.defer.output.resource_group_name
}

module "cloud_fabric" {
  source = "../../../src/000-cloud/031-fabric/terraform"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_prefix = var.resource_prefix

  resource_group                  = data.azurerm_resource_group.existing
  fabric_workspace_name           = var.fabric_workspace_name
  fabric_capacity_admins          = local.fabric_capacity_admins
  should_create_fabric_capacity   = var.should_create_fabric_capacity
  should_create_fabric_eventhouse = var.should_create_fabric_eventhouse
  should_create_fabric_lakehouse  = var.should_create_fabric_lakehouse
  should_create_fabric_workspace  = var.should_create_fabric_workspace
}
