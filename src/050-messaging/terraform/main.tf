/**
 * # Messaging
 *
 * Sets up messaging infrastructure and includes deploying a sample
 * Azure IoT Operations Dataflow to send and receive data from edge to cloud.
 */

module "event_hubs" {
  source = "./modules/event-hubs"

  resource_prefix       = var.resource_prefix
  resource_group_name   = var.aio_resource_group.name
  location              = var.aio_resource_group.location
  aio_uami_principal_id = var.aio_user_assigned_identity.principal_id
}

module "sample_event_hub_dataflow" {
  source = "./modules/event-hub-dataflow"

  resource_prefix      = var.resource_prefix
  custom_location_id   = var.aio_custom_locations.id
  event_hub            = module.event_hubs.event_hub
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_user_assigned_identity.tenant_id
  aio_uami_client_id   = var.aio_user_assigned_identity.client_id
  aio_instance         = var.aio_instance
  aio_dataflow_profile = var.aio_dataflow_profile
}

module "event_grid" {
  source = "./modules/event-grid"

  resource_prefix       = var.resource_prefix
  resource_group_name   = var.aio_resource_group.name
  location              = var.aio_resource_group.location
  aio_uami_principal_id = var.aio_user_assigned_identity.principal_id
}

module "sample_event_grid_dataflow" {
  source = "./modules/event-grid-dataflow"

  resource_prefix      = var.resource_prefix
  custom_location_id   = var.aio_custom_locations.id
  aio_instance         = var.aio_instance
  event_grid           = module.event_grid.event_grid
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_user_assigned_identity.tenant_id
  aio_uami_client_id   = var.aio_user_assigned_identity.client_id
  aio_dataflow_profile = var.aio_dataflow_profile
}
