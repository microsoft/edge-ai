/**
 * # Messaging
 *
 * Creates Azure IoT Operations dataflows for messaging scenarios including
 * Event Hub and Event Grid endpoints for edge-to-cloud data transmission.
 */

module "sample_eventhub_dataflow" {
  count = var.should_create_eventhub_dataflows ? 1 : 0

  source = "./modules/eventhub"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  custom_location_id   = var.aio_custom_locations.id
  eventhub             = var.eventhub
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_identity.tenant_id
  aio_uami_client_id   = var.aio_identity.client_id
  aio_instance         = var.aio_instance
  aio_dataflow_profile = var.aio_dataflow_profile
}

module "sample_eventgrid_dataflow" {
  count = var.should_create_eventgrid_dataflows ? 1 : 0

  source = "./modules/eventgrid"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  custom_location_id   = var.aio_custom_locations.id
  aio_instance         = var.aio_instance
  eventgrid            = var.eventgrid
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_identity.tenant_id
  aio_uami_client_id   = var.aio_identity.client_id
  aio_dataflow_profile = var.aio_dataflow_profile
}
