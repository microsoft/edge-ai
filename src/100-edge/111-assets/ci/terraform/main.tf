/**
 * # CI Configuration for Kubernetes Assets
 *
 * CI configuration for deploying Kubernetes assets.
 */

resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

// Custom location resource via Azure API
data "azapi_resource" "custom_location" {
  type                   = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  parent_id              = data.azurerm_resource_group.aio.id
  name                   = "cl-arck-${var.resource_prefix}-${var.environment}-${var.instance}"
  response_export_values = ["name", "id", "properties.hostResourceId", "properties.namespace", "properties.displayName"]
}

// ADR namespace resource via Azure API
data "azapi_resource" "adr_namespace" {
  type                   = "Microsoft.DeviceRegistry/namespaces@2025-10-01"
  parent_id              = data.azurerm_resource_group.aio.id
  name                   = "adrns-${var.resource_prefix}-${var.environment}-${var.instance}"
  response_export_values = ["name", "id"]
}

module "ci" {
  source = "../../terraform"

  resource_group     = data.azurerm_resource_group.aio
  location           = var.location
  custom_location_id = data.azapi_resource.custom_location.id
  adr_namespace      = data.azapi_resource.adr_namespace

  should_create_default_asset            = var.should_create_default_asset
  should_create_default_namespaced_asset = var.should_create_default_namespaced_asset
  asset_endpoint_profiles                = var.asset_endpoint_profiles
  assets                                 = var.assets
  namespaced_devices                     = var.namespaced_devices
  namespaced_assets                      = var.namespaced_assets
}
