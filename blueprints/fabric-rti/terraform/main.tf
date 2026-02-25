/**
 * # Fabric RTI Minimal Blueprint
 *
 * This blueprint deploys only the essential Fabric RTI components (EventStream with CustomEndpoint → Eventhouse)
 * and edge messaging on top of existing Azure IoT Operations infrastructure, using data sources to reference
 * already deployed resources.
 */

# locals {
#   fabric_eventhouse = var.should_create_fabric_eventhouse ? module.cloud_fabric.fabric_eventhouse : data.fabric_eventhouse.existing
# }

locals {
  fabric_eventhouse = try(coalesce(data.fabric_eventhouse.existing[0]), module.cloud_fabric.fabric_eventhouse, null)
}

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name     = coalesce(var.resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")
    workspace_display_name  = coalesce(var.fabric_workspace_name, "ws-${var.resource_prefix}-${var.environment}-${var.instance}")
    eventhouse_display_name = coalesce(var.fabric_eventhouse_name, "evh-${var.resource_prefix}-${var.environment}-${var.instance}")
    aio_identity_name       = coalesce(var.aio_identity_name, "id-${var.resource_prefix}-aio-${var.environment}-${var.instance}")
    aio_instance_name       = coalesce(var.aio_instance_name, "iotops-arck-${var.resource_prefix}-${var.environment}-${var.instance}")
    custom_location_name    = coalesce(var.custom_location_name, "cl-arck-${var.resource_prefix}-${var.environment}-${var.instance}")
  }
}

/*
 * Data Sources for Existing Resources
 */

data "azurerm_resource_group" "existing" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "aio" {
  name                = terraform_data.defer.output.aio_identity_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "fabric_workspace" "existing" {
  display_name = terraform_data.defer.output.workspace_display_name
}

data "fabric_eventhouse" "existing" {
  count = var.should_create_fabric_eventhouse ? 0 : 1

  workspace_id = data.fabric_workspace.existing.id
  display_name = terraform_data.defer.output.eventhouse_display_name
}

data "azapi_resource" "aio_instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  parent_id = data.azurerm_resource_group.existing.id
  name      = terraform_data.defer.output.aio_instance_name

  response_export_values = ["name", "id"]
}

data "azapi_resource" "custom_location" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  parent_id = data.azurerm_resource_group.existing.id
  name      = terraform_data.defer.output.custom_location_name

  response_export_values = ["name", "id"]
}

data "azapi_resource" "dataflow_profile" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2025-04-01"
  parent_id = data.azapi_resource.aio_instance.id
  name      = "default"

  response_export_values = ["name", "id"]
}

module "cloud_fabric" {
  source = "../../../src/000-cloud/031-fabric/terraform"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_prefix = var.resource_prefix

  resource_group = data.azurerm_resource_group.existing

  should_create_fabric_eventhouse = var.should_create_fabric_eventhouse
  fabric_eventhouse_name          = terraform_data.defer.output.eventhouse_display_name
  fabric_workspace_name           = terraform_data.defer.output.workspace_display_name

  should_create_fabric_capacity  = false
  should_create_fabric_workspace = false
  should_create_fabric_lakehouse = false
}

/*
 * Fabric RTI Component - EventStream with CustomEndpoint → Eventhouse
 */

module "fabric_rti" {
  source = "../../../src/000-cloud/032-fabric-rti/terraform"

  // Basic configuration
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Resource references from data sources
  fabric_workspace = data.fabric_workspace.existing

  // EventStream DAG configuration for AIO telemetry → Eventhouse
  sources_custom_endpoints = [{
    name = "aio-telemetry"
  }]

  streams_default = [{
    name       = "aio-telemetry-stream"
    inputNodes = ["aio-telemetry"]
  }]

  destinations_eventhouse = [{
    name       = "real-time-analytics"
    inputNodes = ["aio-telemetry-stream"]
    properties = merge({
      workspaceId  = data.fabric_workspace.existing.id
      itemId       = tolist(local.fabric_eventhouse.properties.database_ids)[0]
      databaseName = coalesce(var.eventhouse_kql_database_name, local.fabric_eventhouse.display_name)
      inputSerialization = {
        type = "Json"
        properties = {
          encoding = "UTF8"
        }
      }
    }, try({ tableName = coalesce(var.eventstream_table_name) }, {}))
  }]
}

/*
 * Edge Messaging Component - AIO Dataflow Endpoint for Fabric RTI
 */

module "edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  // Basic configuration
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // AIO resource references from data sources
  aio_instance         = data.azapi_resource.aio_instance.output
  aio_custom_locations = data.azapi_resource.custom_location.output
  aio_dataflow_profile = data.azapi_resource.dataflow_profile.output
  aio_identity         = data.azurerm_user_assigned_identity.aio

  // Fabric RTI connection details from fabric-rti component
  should_create_fabric_rti_dataflows = true

  fabric_eventstream_endpoint = {
    bootstrap_server = module.fabric_rti.custom_endpoint_source_connections["aio-telemetry"].bootstrap_server
    topic_name       = module.fabric_rti.custom_endpoint_source_connections["aio-telemetry"].topic_name
    endpoint_type    = "FabricRealTimeIntelligence"
  }

  // Fabric workspace dependency for role assignment
  fabric_workspace = data.fabric_workspace.existing

  // Disable other dataflow types
  should_create_eventgrid_dataflows = var.should_create_eventgrid_dataflows
  should_create_eventhub_dataflows  = var.should_create_eventhub_dataflows
}
