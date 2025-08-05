/*
 * EventStream Connection Details
 */

output "custom_endpoint_source_connections" {
  description = "CustomEndpoint connection details."
  value = tomap({
    for k, v in data.fabric_eventstream_source_connection.custom_endpoint_source : k => {
      // Entra ID Connection Settings
      bootstrap_server = "${v.fully_qualified_namespace}:9093"
      topic_name       = v.event_hub_name

      eventstream_id = v.eventstream_id
      source_id      = v.source_id
      workspace_id   = v.workspace_id
    }
  })
}

/*
 * EventStream Resource Details
 */

output "eventstream" {
  description = "The created EventStream resource details."
  value = {
    id           = fabric_eventstream.rti_eventstream.id
    display_name = fabric_eventstream.rti_eventstream.display_name
    workspace_id = fabric_eventstream.rti_eventstream.workspace_id
  }
}

output "eventstream_destinations" {
  description = "The EventStream destination nodes with their configuration details."
  value = [
    for dest in local.eventstream_destinations : {
      id   = dest.id
      name = dest.name
      type = dest.type
    }
  ]
}

output "eventstream_sources" {
  description = "The EventStream source nodes with their configuration details."
  value = [
    for source in local.eventstream_sources : {
      id   = source.id
      name = source.name
      type = source.type
    }
  ]
}

output "eventstream_streams" {
  description = "The EventStream stream nodes with their configuration details."
  value = [
    for stream in local.eventstream_streams : {
      id   = stream.id
      name = stream.name
      type = stream.type
    }
  ]
}

/*
 * DAG Configuration Statistics
 */

output "eventstream_dag_configuration" {
  description = "The DAG configuration used for EventStream creation."
  value = {
    sources_count      = length(var.sources_custom_endpoints)
    destinations_count = length(var.destinations_eventhouse)
    streams_count      = length(var.streams_derived)
    operators_count    = length(local.eventstream_operators)
    node_names = concat(
      [for source in var.sources_custom_endpoints : source.name],
      [for dest in var.destinations_eventhouse : dest.name],
      [for stream in var.streams_derived : stream.name],
      [for op in var.operators_filter : op.name],
      [for op in var.operators_group_by : op.name],
      [for op in var.operators_join : op.name],
      [for op in var.operators_manage_fields : op.name],
      [for op in var.operators_aggregate : op.name],
      [for op in var.operators_union : op.name],
      [for op in var.operators_expand : op.name]
    )
  }
}
