/**
 * # Dataflow Graphs Module
 *
 * Creates Azure IoT Operations dataflow graphs for processing data through WASM operators
 * or standard dataflow nodes. Supports source, destination, and graph-based processing nodes.
 */

resource "azapi_resource" "dataflow_graph" {
  for_each = { for graph in var.dataflow_graphs : graph.name => graph }

  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflowGraphs@2025-10-01"
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
      nodes = [
        for node in each.value.nodes : merge(
          { nodeType = node.nodeType, name = node.name },
          node.sourceSettings != null ? { sourceSettings = node.sourceSettings } : {},
          node.graphSettings != null ? { graphSettings = node.graphSettings } : {},
          node.destinationSettings != null ? { destinationSettings = node.destinationSettings } : {}
        )
      ]
      nodeConnections = each.value.node_connections
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}
