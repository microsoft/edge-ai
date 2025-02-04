/**
 * # Azure IoT Operations Dataflow sample
 *
 * Provisions the ARM based data flow endpoint and data flow, requires Asset
 */

resource "azapi_resource" "dataflow_endpoint_to_event_hub" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2024-11-01"
  name      = "dfe-eh-${var.resource_prefix}-sample"
  parent_id = var.aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      endpointType = "Kafka"
      kafkaSettings = {
        host = "${var.event_hub.namespace_name}.servicebus.windows.net:9093"
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
}

resource "azapi_resource" "dataflow_to_event_hub" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2024-11-01"
  name      = "df-eh-${var.resource_prefix}-passthrough"
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
            assetRef            = var.asset_name
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
            endpointRef     = azapi_resource.dataflow_endpoint_to_event_hub.name
            dataDestination = var.event_hub.event_hub_name
          }
        }
      ]
    }
  }
}
