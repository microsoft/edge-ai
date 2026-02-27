/**
 * # Dataflow Module
 *
 * Creates Azure IoT Operations dataflows for processing data through source,
 * built-in transformation, and destination operations.
 */

resource "azapi_resource" "dataflow" {
  for_each = { for df in var.dataflows : df.name => df }

  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-10-01"
  name      = each.value.name
  parent_id = var.aio_dataflow_profile.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location.id
    }
    properties = {
      mode                   = each.value.mode
      requestDiskPersistence = each.value.request_disk_persistence
      operations = [
        for op in each.value.operations : merge(
          { operationType = op.operationType },
          op.name != null ? { name = op.name } : {},
          op.sourceSettings != null ? { sourceSettings = op.sourceSettings } : {},
          op.builtInTransformationSettings != null ? { builtInTransformationSettings = op.builtInTransformationSettings } : {},
          op.destinationSettings != null ? { destinationSettings = op.destinationSettings } : {}
        )
      ]
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}
