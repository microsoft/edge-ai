/**
 * # Azure IoT Operations Dataflow sample
 *
 * Provisions the ARM based data flow endpoint and data flow, requires Asset
 */

locals {
  asset_ref = var.adr_namespace != null ? "${var.adr_namespace.name}/${var.asset_name}" : var.asset_name
}

resource "azapi_resource" "dataflow_endpoint_to_eventhub" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-07-01-preview"
  name      = "dfe-eh-${var.resource_prefix}-${var.environment}-sample-${var.instance}"
  parent_id = var.aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      endpointType = "Kafka"
      kafkaSettings = {
        host = "${var.eventhub.namespace_name}.servicebus.windows.net:9093"
        batching = {
          latencyMs   = 0
          maxMessages = 100
        }
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

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "dataflow_to_eventhub" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-07-01-preview"
  name      = "df-eh-${var.resource_prefix}-${var.environment}-passthrough-${var.instance}"
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
            endpointRef     = azapi_resource.dataflow_endpoint_to_eventhub.name
            dataDestination = var.eventhub.eventhub_name
          }
        }
      ]
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}
