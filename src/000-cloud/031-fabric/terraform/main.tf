/**
 * # Cloud Fabric
 *
 * Contains all the resources needed for Fabric based resources.
 */

locals {
  fabric_workspace_name   = "ws-${var.resource_prefix}-${var.environment}-${var.instance}"
  fabric_lakehouse_name   = "lh${var.resource_prefix}${var.environment}${var.instance}"
  fabric_eventstream_name = "es-${var.resource_prefix}es-${var.environment}-${var.instance}"
  fabric_capacity_name    = "cap${var.resource_prefix}${var.environment}${var.instance}"

  workspace_id = try(coalesce(var.existing_fabric_workspace_id, module.fabric_workspace[0].workspace_id), null)
}

module "fabric_capacity" {
  source = "./modules/capacity"

  create_capacity     = var.should_create_fabric_capacity
  capacity_id         = var.fabric_capacity_id
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
  capacity_id            = var.capacity_id
}

module "fabric_lakehouse" {
  count = var.should_create_fabric_lakehouse ? 1 : 0

  source = "./modules/lakehouse"

  lakehouse_display_name = local.fabric_lakehouse_name
  lakehouse_description  = var.lakehouse_description
  workspace_id           = local.workspace_id
}

module "fabric_eventstream" {
  count = var.should_create_fabric_eventstream ? 1 : 0

  source = "./modules/eventstream"

  eventstream_display_name = local.fabric_eventstream_name
  eventstream_description  = var.eventstream_description
  workspace_id             = local.workspace_id
  lakehouse_id             = module.fabric_lakehouse[0].lakehouse_id
  eventhub_endpoint        = var.eventhub_endpoint
}
