/**
 * # Azure IoT Operations Dataflow sample
 *
 * Provisions the ARM based data flow endpoint and data flow, requires Asset
 */

data "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  name      = var.aio_instance_name
  parent_id = var.resource_group_id
}

data "azapi_resource" "data_flow_profile" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2024-11-01"
  name      = "default"
  parent_id = data.azapi_resource.instance.id
}

resource "azapi_resource" "data_flow_endpoint_to_event_hub" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2024-11-01"
  name      = "dfe-eh-${var.resource_prefix}-sample"
  parent_id = data.azapi_resource.instance.id

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
          method                                = "SystemAssignedManagedIdentity"
          systemAssignedManagedIdentitySettings = {}
        }
      }
    }
  }
}

resource "azapi_resource" "data_flow" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2024-11-01"
  name      = "df-${var.resource_prefix}-passthrough"
  parent_id = data.azapi_resource.data_flow_profile.id

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
            endpointRef     = azapi_resource.data_flow_endpoint_to_event_hub.name
            dataDestination = var.event_hub.event_hub_name
          }
        }
      ]
    }
  }
}
