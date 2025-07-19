locals {
  resource_group_name = try(coalesce(var.resource_group.name), "rg-${var.resource_prefix}-${var.environment}-${var.instance}")
}

module "cloud_fabric" {
  source = "../../../src/000-cloud/031-fabric/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance
  capacity_id     = var.capacity_id

  resource_group                   = { name : local.resource_group_name }
  should_create_fabric_capacity    = var.should_create_fabric_capacity
  should_create_fabric_eventstream = var.should_create_fabric_eventstream
  should_create_fabric_lakehouse   = var.should_create_fabric_lakehouse
  should_create_fabric_workspace   = var.should_create_fabric_workspace
  // eventhub_endpoint = module.cloud_messaging.eventhubs. fill_in
}
