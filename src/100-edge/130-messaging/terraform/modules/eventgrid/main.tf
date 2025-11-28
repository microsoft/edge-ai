/**
 * # Azure IoT Operations Dataflow Event Grid sample
 *
 * Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset
 */

locals {
  asset_ref = var.adr_namespace != null ? "${var.adr_namespace.name}/${var.asset_name}" : var.asset_name
}

resource "azapi_resource" "dataflow_endpoint_to_eventgrid" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-10-01"
  name      = "dfe-eg-${var.resource_prefix}-${var.environment}-sample-${var.instance}"
  parent_id = var.aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        host = var.eventgrid.endpoint
        tls = {
          mode = "Enabled"
        }
        authentication = {
          method = "UserAssignedManagedIdentity"
          userAssignedManagedIdentitySettings = {
            tenantId = var.aio_uami_tenant_id
            clientId = var.aio_uami_client_id
          }
        }
      }
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-10-01 until azapi provider supports it
}

resource "azapi_resource" "dataflow_to_eventgrid" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-10-01"
  name      = "df-eg-${var.resource_prefix}-${var.environment}-passthrough-${var.instance}"
  parent_id = var.aio_dataflow_profile.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      mode = "Enabled"
      operations = [
        {
          operationType = "Source"
          sourceSettings = {
            endpointRef         = "default"
            assetRef            = local.asset_ref
            serializationFormat = "Json"
            dataSources         = ["azure-iot-operations/data/${var.asset_name}"]
          }
        },
        {
          operationType = "BuiltInTransformation"
          builtInTransformationSettings = {
            serializationFormat = "Json"
            map = [
              {
                type   = "PassThrough"
                inputs = ["*"]
                output = "*"
              }
            ]
          }
        },
        {
          operationType = "Destination"
          destinationSettings = {
            endpointRef     = azapi_resource.dataflow_endpoint_to_eventgrid.name
            dataDestination = var.eventgrid.topic_name
          }
        }
      ]
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-10-01 until azapi provider supports it
}
