/**
 * # Cloud Fabric
 *
 * Contains all the resources needed for Fabric based resources.
 */

locals {
  fabric_workspace_name  = coalesce(var.fabric_workspace_name, "ws-${var.resource_prefix}-${var.environment}-${var.instance}")
  fabric_lakehouse_name  = coalesce(var.fabric_lakehouse_name, "lh-${var.resource_prefix}-${var.environment}-${var.instance}")
  fabric_eventhouse_name = coalesce(var.fabric_eventhouse_name, "evh-${var.resource_prefix}-${var.environment}-${var.instance}")
  fabric_capacity_name   = coalesce(var.fabric_capacity_name, "cap-${var.resource_prefix}-${var.environment}-${var.instance}")

  capacity_id  = try(module.fabric_capacity[0].capacity.id, data.fabric_capacity.existing[0].id, null)
  workspace_id = try(module.fabric_workspace[0].workspace.id, data.fabric_workspace.existing[0].id, null)
}

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
resource "terraform_data" "defer_fabric_capacity" {
  count = var.should_create_fabric_capacity ? 0 : var.should_create_fabric_workspace ? 1 : 0
  input = {
    display_name = local.fabric_capacity_name
  }
}

data "fabric_capacity" "existing" {
  count        = length(terraform_data.defer_fabric_capacity)
  display_name = terraform_data.defer_fabric_capacity[0].output.display_name
}

resource "terraform_data" "defer_fabric_workspace" {
  count = var.should_create_fabric_workspace ? 0 : 1
  input = {
    display_name = local.fabric_workspace_name
  }
}

data "fabric_workspace" "existing" {
  count        = length(terraform_data.defer_fabric_workspace)
  display_name = terraform_data.defer_fabric_workspace[0].output.display_name
}

module "fabric_capacity" {
  count = var.should_create_fabric_capacity ? 1 : 0

  source = "./modules/capacity"

  name                = local.fabric_capacity_name
  resource_group_name = var.resource_group.name
  location            = var.location
  sku                 = var.fabric_capacity_sku
  admin_members       = var.fabric_capacity_admins
}

module "fabric_workspace" {
  count = var.should_create_fabric_workspace ? 1 : 0

  source = "./modules/workspace"

  workspace_display_name = local.fabric_workspace_name
  workspace_description  = var.workspace_description
  capacity_id            = local.capacity_id
}

module "fabric_lakehouse" {
  count = var.should_create_fabric_lakehouse ? 1 : 0

  source = "./modules/lakehouse"

  lakehouse_display_name = local.fabric_lakehouse_name
  lakehouse_description  = var.lakehouse_description
  workspace_id           = local.workspace_id
}

module "fabric_eventhouse" {
  count = var.should_create_fabric_eventhouse ? 1 : 0

  source = "./modules/eventhouse"

  eventhouse_display_name  = local.fabric_eventhouse_name
  eventhouse_description   = var.eventhouse_description
  workspace_id             = local.workspace_id
  additional_kql_databases = var.additional_kql_databases
}
