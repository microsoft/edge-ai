/**
 * # Azure IoT Operations Dataflow Event Grid sample
 *
 * Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset
 */

data "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  name      = var.aio_instance_name
  parent_id = var.resource_group_id
}

# For troubleshooting, a custom dataflow profile can be created with a higher log level
# https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/howto-configure-dataflow-profile?tabs=bicep#tabpanel_4_bicep
data "azapi_resource" "dataflow_profile" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2024-11-01"
  name      = "default"
  parent_id = data.azapi_resource.instance.id
}

resource "azapi_resource" "dataflow_endpoint_to_event_grid" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2024-11-01"
  name      = "dfe-eg-${var.resource_prefix}-sample"
  parent_id = data.azapi_resource.instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        host = var.event_grid.endpoint
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

resource "azapi_resource" "dataflow_to_event_grid" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2024-11-01"
  name      = "df-eg-${var.resource_prefix}-passthrough"
  parent_id = data.azapi_resource.dataflow_profile.id

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
            endpointRef     = azapi_resource.dataflow_endpoint_to_event_grid.name
            dataDestination = var.event_grid.topic_name
          }
        }
      ]
    }
  }
}
