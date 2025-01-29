/**
 * # Messaging
 *
 * Sets up messaging infrastructure and includes deploying a sample
 * Azure IoT Operations Dataflow to send and receive data from edge to cloud.
 */

locals {
  connected_cluster_name = coalesce(var.connected_cluster_name, "${var.resource_prefix}-arc")
  custom_locations_name  = coalesce(var.custom_locations_name, "${local.connected_cluster_name}-cl")
  iot_ops_instance_name  = coalesce(var.iot_ops_instance_name, "${local.connected_cluster_name}-ops-instance")
}

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_resource_group" "aio_rg" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "aio_uami" {
  name                = coalesce(var.aio_uami_name, "${var.resource_prefix}-aio-uami")
  resource_group_name = data.azurerm_resource_group.aio_rg.name
}

data "azapi_resource" "custom_locations" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  name      = local.custom_locations_name
  parent_id = data.azurerm_resource_group.aio_rg.id
}

module "event_hubs" {
  source = "./modules/event-hubs"

  resource_prefix       = var.resource_prefix
  resource_group_name   = data.azurerm_resource_group.aio_rg.name
  location              = data.azurerm_resource_group.aio_rg.location
  aio_uami_principal_id = data.azurerm_user_assigned_identity.aio_uami.principal_id
}

module "sample_event_hub_dataflow" {
  source = "./modules/event-hub-dataflow"

  resource_prefix    = var.resource_prefix
  resource_group_id  = data.azurerm_resource_group.aio_rg.id
  custom_location_id = data.azapi_resource.custom_locations.id
  aio_instance_name  = local.iot_ops_instance_name
  event_hub          = module.event_hubs.event_hub
  asset_name         = var.asset_name
  aio_uami_tenant_id = data.azurerm_user_assigned_identity.aio_uami.tenant_id
  aio_uami_client_id = data.azurerm_user_assigned_identity.aio_uami.client_id
}
