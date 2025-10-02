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
  name                = "id-${var.resource_prefix}-${var.environment}-aio-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azapi_resource" "aio_instance" {
  type      = "Microsoft.IoTOperations/instances@2025-07-01-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "arck-${var.resource_prefix}-${var.environment}-${var.instance}-ops-instance"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "aio_custom_locations" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "arck-${var.resource_prefix}-${var.environment}-${var.instance}-cl"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "aio_dataflow_profile" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2025-07-01-preview"
  parent_id = data.azapi_resource.aio_instance.id
  name      = "default"

  response_export_values = ["name", "id"]

}

module "ci" {
  source = "../../terraform"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  aio_instance         = data.azapi_resource.aio_instance.output
  aio_custom_locations = data.azapi_resource.aio_custom_locations.output
  aio_identity         = data.azurerm_user_assigned_identity.aio
  aio_dataflow_profile = data.azapi_resource.aio_dataflow_profile.output

  should_create_eventgrid_dataflows  = false
  should_create_eventhub_dataflows   = false
  should_create_fabric_rti_dataflows = var.fabric_eventstream_endpoint != null && var.fabric_workspace != null

  // Fabric RTI Configuration for CI Testing
  fabric_eventstream_endpoint = var.fabric_eventstream_endpoint
  fabric_workspace            = var.fabric_workspace
}
