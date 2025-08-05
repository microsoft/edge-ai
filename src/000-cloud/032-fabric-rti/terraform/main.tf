/**
 * # Microsoft Fabric RTI Component
 *
 * Creates EventStream with Go template-based DAG configuration supporting CustomEndpoint sources,
 * Eventhouse destinations, DerivedStreams, and all available operators for flexible data flow design.
 */

locals {
  // Construct sources array
  eventstream_sources = [
    for source in var.sources_custom_endpoints : {
      id         = uuidv5("x500", "CN=${source.name}")
      name       = source.name
      type       = "CustomEndpoint"
      properties = source.properties
    }
  ]

  // Construct destinations array
  eventstream_destinations = concat(
    // Eventhouse destinations
    [
      for dest in var.destinations_eventhouse : {
        id   = uuidv5("x500", "CN=${dest.name}")
        name = dest.name
        type = "Eventhouse"
        properties = merge(dest.properties, {
          tableName = coalesce(dest.properties.tableName, local.eventstream_name)
        })
        inputNodes   = [for node_name in dest.inputNodes : { name = node_name }]
        inputSchemas = []
      }
    ],
    // Lakehouse destinations
    [
      for dest in var.destinations_lakehouse : {
        id   = uuidv5("x500", "CN=${dest.name}")
        name = dest.name
        type = "Lakehouse"
        properties = merge(dest.properties, {
          workspaceId = dest.properties.workspaceId
          itemId      = dest.properties.itemId
        })
        inputNodes   = [for node_name in dest.inputNodes : { name = node_name }]
        inputSchemas = []
      }
    ],
  )

  // Construct derived streams array
  eventstream_derived_streams = [
    for stream in var.streams_derived : {
      id         = uuidv5("x500", "CN=${stream.name}")
      name       = stream.name
      type       = "DerivedStream"
      properties = stream.properties
      inputNodes = [for node_name in stream.inputNodes : { name = node_name }]
    }
  ]

  // Construct default stream (required when sources exist)
  eventstream_name = "es-${var.resource_prefix}-${var.environment}-${var.instance}"
  eventstream_default_stream = [
    for stream in var.streams_default : {
      id         = uuidv5("x500", "CN=DefaultStream")
      name       = coalesce(stream.name, "${local.eventstream_name}-stream")
      type       = "DefaultStream"
      properties = stream.properties
      inputNodes = [for node_name in stream.inputNodes : { name = node_name }]
  }]

  // Combine all streams
  eventstream_streams = concat(
    local.eventstream_default_stream,
    local.eventstream_derived_streams
  )

  // Construct operators arrays
  eventstream_filter_operators = [
    for op in var.operators_filter : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "Filter"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_group_by_operators = [
    for op in var.operators_group_by : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "GroupBy"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_join_operators = [
    for op in var.operators_join : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "Join"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_manage_fields_operators = [
    for op in var.operators_manage_fields : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "ManageFields"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_aggregate_operators = [
    for op in var.operators_aggregate : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "Aggregate"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_union_operators = [
    for op in var.operators_union : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "Union"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  eventstream_expand_operators = [
    for op in var.operators_expand : {
      id         = uuidv5("x500", "CN=${op.name}")
      name       = op.name
      type       = "Expand"
      properties = op.properties
      inputNodes = [for node_name in op.inputNodes : { name = node_name }]
    }
  ]

  // Combine all operators
  eventstream_operators = concat(
    local.eventstream_filter_operators,
    local.eventstream_group_by_operators,
    local.eventstream_join_operators,
    local.eventstream_manage_fields_operators,
    local.eventstream_aggregate_operators,
    local.eventstream_union_operators,
    local.eventstream_expand_operators
  )

  // Construct complete EventStream definition JSON with both content and properties
  eventstream_definition = {
    compatibilityLevel = "1.1"
    sources            = local.eventstream_sources
    destinations       = local.eventstream_destinations
    streams            = local.eventstream_streams
    operators          = local.eventstream_operators
    properties = {
      retentionTimeInDays  = var.retention_days
      eventThroughputLevel = var.throughput_level
    }
  }

  // Template configuration - use override files if provided, otherwise use generated content
  eventstream_template_source = var.eventstream_template_file_path != null ? var.eventstream_template_file_path : "${path.module}/templates/eventstream.json.tmpl"
  eventstream_template_tokens = var.eventstream_template_file_path != null ? var.template_tokens : {
    "Content" = jsonencode(local.eventstream_definition)
  }
}

// EventStream with Go template-based DAG configuration
resource "fabric_eventstream" "rti_eventstream" {
  display_name = local.eventstream_name
  workspace_id = var.fabric_workspace.id
  description  = "EventStream with DAG-based configuration for AIO RTI data flow"
  format       = "Default"

  definition = {
    "eventstream.json" = {
      source = local.eventstream_template_source
      tokens = local.eventstream_template_tokens
    }
  }
}

data "fabric_eventstream_source_connection" "custom_endpoint_source" {
  for_each = {
    for source in local.eventstream_sources : source.name => source
    if source.type == "CustomEndpoint"
  }

  depends_on = [fabric_eventstream.rti_eventstream]

  eventstream_id = fabric_eventstream.rti_eventstream.id
  source_id      = each.value.id
  workspace_id   = var.fabric_workspace.id
}
