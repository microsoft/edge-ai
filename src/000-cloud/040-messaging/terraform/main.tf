/**
 * # Messaging
 *
 * Sets up messaging infrastructure and includes deploying a sample
 * Azure IoT Operations Dataflow to send and receive data from edge to cloud.
 */

module "event_hubs" {
  count = var.should_create_event_hubs ? 1 : 0

  source = "./modules/event-hubs"

  resource_prefix       = var.resource_prefix
  environment           = var.environment
  instance              = var.instance
  resource_group_name   = var.resource_group.name
  location              = var.resource_group.location
  aio_uami_principal_id = var.aio_identity.principal_id
}

module "event_grid" {
  count = var.should_create_event_grid ? 1 : 0

  source = "./modules/event-grid"

  resource_prefix       = var.resource_prefix
  environment           = var.environment
  instance              = var.instance
  resource_group_name   = var.resource_group.name
  location              = var.resource_group.location
  aio_uami_principal_id = var.aio_identity.principal_id
}
