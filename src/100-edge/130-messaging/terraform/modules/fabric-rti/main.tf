/**
 * # Fabric RTI DataFlow for Edge Messaging
 *
 * Creates a DataFlow endpoint and dataflow for Microsoft Fabric Real-Time Intelligence integration.
 * This module enables direct data flow from Azure IoT Operations to Fabric RTI
 * via Kafka-compatible interface with managed identity authentication.
 */

// Role assignment for AIO managed identity to Fabric workspace
resource "fabric_workspace_role_assignment" "fabric_workspace_contributor" {
  workspace_id = var.fabric_workspace.id
  principal = {
    id   = var.aio_identity.principal_id
    type = "ServicePrincipal"
  }
  role = "Contributor"
}

resource "azapi_resource" "fabric_rti_endpoint" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-07-01-preview"
  name      = "dfe-fabric-rti-${var.resource_prefix}-${var.environment}-${var.instance}"
  parent_id = var.aio_instance.id

  depends_on = [fabric_workspace_role_assignment.fabric_workspace_contributor]

  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      endpointType = "Kafka"
      kafkaSettings = {
        host = var.fabric_eventstream_endpoint.bootstrap_server
        authentication = {
          method = "UserAssignedManagedIdentity"
          userAssignedManagedIdentitySettings = {
            tenantId = var.aio_identity.tenant_id
            clientId = var.aio_identity.client_id
          }
        }
        tls = {
          mode = "Enabled"
        }
      }
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "fabric_rti_dataflow" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-07-01-preview"
  name      = "df-fabric-rti-${var.resource_prefix}-${var.environment}-${var.instance}"
  parent_id = var.aio_dataflow_profile.id

  depends_on = [azapi_resource.fabric_rti_endpoint]

  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      mode = "Enabled"
      operations = [
        {
          operationType = "Source"
          sourceSettings = {
            endpointRef = "default"
            assetRef    = var.asset_name
            dataSources = [
              "azure-iot-operations/data/${var.asset_name}"
            ]
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
            endpointRef     = azapi_resource.fabric_rti_endpoint.name
            dataDestination = var.fabric_eventstream_endpoint.topic_name
          }
        }
      ]
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}
