module "sample_event_hub_dataflow" {
  count = var.event_hub != null ? 1 : 0

  source = "./modules/event-hub"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  custom_location_id   = var.aio_custom_locations.id
  event_hub            = var.event_hub
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_identity.tenant_id
  aio_uami_client_id   = var.aio_identity.client_id
  aio_instance         = var.aio_instance
  aio_dataflow_profile = var.aio_dataflow_profile
}

module "sample_event_grid_dataflow" {
  count = var.event_grid != null ? 1 : 0

  source = "./modules/event-grid"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  custom_location_id   = var.aio_custom_locations.id
  aio_instance         = var.aio_instance
  event_grid           = var.event_grid
  asset_name           = var.asset_name
  aio_uami_tenant_id   = var.aio_identity.tenant_id
  aio_uami_client_id   = var.aio_identity.client_id
  aio_dataflow_profile = var.aio_dataflow_profile
}
