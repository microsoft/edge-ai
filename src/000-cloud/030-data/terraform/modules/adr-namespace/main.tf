/**
 * # Azure Device Registry Namespace
 *
 * Creates an ADR namespace for organizing assets and devices in Azure IoT Operations.
 */

resource "azapi_resource" "adr_namespace" {
  type      = "Microsoft.DeviceRegistry/namespaces@2025-10-01"
  parent_id = var.resource_group.id
  name      = var.adr_namespace_name
  location  = var.location

  body = {
    properties = {
      messaging = try({ endpoints = coalesce(var.messaging_endpoints) }, null)
    }
    identity = var.enable_system_assigned_identity ? {
      type = "SystemAssigned"
    } : null
  }

  response_export_values = ["name", "id", "properties.uuid"]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-10-01 until azapi provider supports it

  lifecycle {
    ignore_changes = [
      body.properties.provisioningState
    ]
  }
}
