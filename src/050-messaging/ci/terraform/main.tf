# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "aio" {
  name                = "${var.resource_prefix}-aio-uami"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azapi_resource" "aio_instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "${var.resource_prefix}-arc-ops-instance"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "aio_custom_locations" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "${var.resource_prefix}-arc-cl"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "aio_dataflow_profile" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2024-11-01"
  parent_id = data.azapi_resource.aio_instance.id
  name      = "default"

  response_export_values = ["name", "id"]
}

module "messaging" {
  source = "../../terraform"

  resource_prefix            = var.resource_prefix
  aio_resource_group         = data.azurerm_resource_group.aio
  aio_instance               = data.azapi_resource.aio_instance.output
  aio_custom_locations       = data.azapi_resource.aio_custom_locations.output
  aio_user_assigned_identity = data.azurerm_user_assigned_identity.aio
  aio_dataflow_profile       = data.azapi_resource.aio_dataflow_profile.output
}
