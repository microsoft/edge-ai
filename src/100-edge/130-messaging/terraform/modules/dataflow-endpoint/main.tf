/**
 * # Dataflow Endpoint Module
 *
 * Creates Azure IoT Operations dataflow endpoints for connecting dataflows to
 * external services such as Kafka, MQTT, Data Explorer, Data Lake Storage,
 * Fabric OneLake, local storage, and OpenTelemetry.
 */

resource "azapi_resource" "dataflow_endpoint" {
  for_each = { for ep in var.dataflow_endpoints : ep.name => ep }

  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-10-01"
  name      = each.value.name
  parent_id = var.aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location.id
    }
    properties = merge(
      { endpointType = each.value.endpointType },
      each.value.hostType != null ? { hostType = each.value.hostType } : {},
      each.value.dataExplorerSettings != null ? { dataExplorerSettings = each.value.dataExplorerSettings } : {},
      each.value.dataLakeStorageSettings != null ? { dataLakeStorageSettings = each.value.dataLakeStorageSettings } : {},
      each.value.fabricOneLakeSettings != null ? { fabricOneLakeSettings = each.value.fabricOneLakeSettings } : {},
      each.value.kafkaSettings != null ? { kafkaSettings = each.value.kafkaSettings } : {},
      each.value.localStorageSettings != null ? { localStorageSettings = each.value.localStorageSettings } : {},
      each.value.mqttSettings != null ? { mqttSettings = each.value.mqttSettings } : {},
      each.value.openTelemetrySettings != null ? { openTelemetrySettings = each.value.openTelemetrySettings } : {}
    )
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}
