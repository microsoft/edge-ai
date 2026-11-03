mock_provider "azurerm" {}

mock_provider "fabric" {}

# Call the setup module to create a random resource prefix and Fabric item IDs
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: Minimal configuration creates an empty EventStream from the generated template
run "create_minimal_eventstream" {
  command = plan

  variables {
    resource_prefix  = run.setup_tests.resource_prefix
    environment      = "test"
    instance         = "001"
    fabric_workspace = run.setup_tests.fabric_workspace
  }

  assert {
    condition     = fabric_eventstream.rti_eventstream.display_name == "es-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "EventStream name does not match expected pattern"
  }

  assert {
    condition     = fabric_eventstream.rti_eventstream.workspace_id == var.fabric_workspace.id
    error_message = "EventStream should be created in the provided Fabric workspace"
  }

  assert {
    condition     = endswith(fabric_eventstream.rti_eventstream.definition["eventstream.json"].source, "templates/eventstream.json.tmpl")
    error_message = "EventStream should use the bundled template when no template override is provided"
  }

  assert {
    condition     = length(jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).sources) == 0
    error_message = "EventStream definition should have no sources by default"
  }

  assert {
    condition     = length(jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations) == 0
    error_message = "EventStream definition should have no destinations by default"
  }

  assert {
    condition     = length(jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams) == 0
    error_message = "EventStream definition should have no streams by default"
  }

  assert {
    condition     = length(jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).operators) == 0
    error_message = "EventStream definition should have no operators by default"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).properties.retentionTimeInDays == 7
    error_message = "EventStream retention should default to 7 days"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).properties.eventThroughputLevel == "Medium"
    error_message = "EventStream throughput level should default to Medium"
  }

  assert {
    condition     = length(data.fabric_eventstream_source_connection.custom_endpoint_source) == 0
    error_message = "No source connections should be looked up without custom endpoint sources"
  }
}

# Test 2: CI-style DAG with a custom endpoint, default stream and Eventhouse and Lakehouse destinations
run "create_eventstream_with_destinations" {
  command = plan

  variables {
    resource_prefix  = run.setup_tests.resource_prefix
    environment      = "test"
    instance         = "001"
    fabric_workspace = run.setup_tests.fabric_workspace

    sources_custom_endpoints = [{
      name = "aio-telemetry"
    }]

    streams_default = [{
      inputNodes = ["aio-telemetry"]
    }]

    destinations_eventhouse = [{
      name       = "real-time-analytics"
      inputNodes = ["es-${run.setup_tests.resource_prefix}-test-001-stream"]
      properties = {
        workspaceId  = run.setup_tests.fabric_workspace.id
        itemId       = run.setup_tests.eventhouse_database_id
        databaseName = "telemetry"
      }
    }]

    destinations_lakehouse = [{
      name       = "historical-analytics"
      inputNodes = ["es-${run.setup_tests.resource_prefix}-test-001-stream"]
      properties = {
        workspaceId = run.setup_tests.fabric_workspace.id
        itemId      = run.setup_tests.lakehouse_id
        deltaTable  = "telemetry"
      }
    }]

    retention_days   = 30
    throughput_level = "High"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).sources[0].id == uuidv5("x500", "CN=aio-telemetry")
    error_message = "Source IDs should be derived from the source name"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).sources[0].type == "CustomEndpoint"
    error_message = "Custom endpoint sources should use the CustomEndpoint type"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams[0].name == "es-${var.resource_prefix}-${var.environment}-${var.instance}-stream"
    error_message = "Default stream name should default to the EventStream name with a -stream suffix"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams[0].type == "DefaultStream"
    error_message = "Default stream should use the DefaultStream type"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams[0].inputNodes == [{ name = "aio-telemetry" }]
    error_message = "Default stream input nodes should reference the source by name"
  }

  assert {
    condition     = [for dest in jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations : dest.type] == ["Eventhouse", "Lakehouse"]
    error_message = "Eventhouse destinations should come before Lakehouse destinations"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations[0].properties.tableName == "es-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Eventhouse table name should default to the EventStream name"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations[0].properties.dataIngestionMode == "ProcessedIngestion"
    error_message = "Eventhouse ingestion mode should default to ProcessedIngestion"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations[1].properties.itemId == run.setup_tests.lakehouse_id
    error_message = "Lakehouse destination should use the provided item ID"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).destinations[1].properties.schema == "dbo"
    error_message = "Lakehouse destination schema should default to dbo"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).properties.retentionTimeInDays == 30
    error_message = "EventStream retention should use the provided value"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).properties.eventThroughputLevel == "High"
    error_message = "EventStream throughput level should use the provided value"
  }

  assert {
    condition     = keys(data.fabric_eventstream_source_connection.custom_endpoint_source) == ["aio-telemetry"]
    error_message = "A source connection should be looked up for each custom endpoint source"
  }

  assert {
    condition     = data.fabric_eventstream_source_connection.custom_endpoint_source["aio-telemetry"].source_id == uuidv5("x500", "CN=aio-telemetry")
    error_message = "Source connection lookup should use the generated source ID"
  }
}

# Test 3: Operators and derived streams are added to the DAG
run "create_eventstream_with_operators" {
  command = plan

  variables {
    resource_prefix  = run.setup_tests.resource_prefix
    environment      = "test"
    fabric_workspace = run.setup_tests.fabric_workspace

    sources_custom_endpoints = [{
      name = "aio-telemetry"
    }]

    streams_default = [{
      name       = "telemetry-stream"
      inputNodes = ["aio-telemetry"]
    }]

    operators_filter = [{
      name       = "high-temperature"
      inputNodes = ["telemetry-stream"]
      properties = {
        conditions = [{
          column = {
            columnName = "temperature"
          }
          operatorType = "GreaterThan"
          value = {
            dataType = "Double"
            value    = "50"
          }
        }]
      }
    }]

    operators_union = [{
      name       = "all-alerts"
      inputNodes = ["high-temperature"]
    }]

    streams_derived = [{
      name       = "alerts-stream"
      inputNodes = ["all-alerts"]
    }]
  }

  assert {
    condition     = [for stream in jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams : stream.type] == ["DefaultStream", "DerivedStream"]
    error_message = "Default stream should come before derived streams"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams[0].name == "telemetry-stream"
    error_message = "Default stream should use the provided name"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).streams[1].inputNodes == [{ name = "all-alerts" }]
    error_message = "Derived stream input nodes should reference the operator by name"
  }

  assert {
    condition     = [for op in jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).operators : op.type] == ["Filter", "Union"]
    error_message = "Operators should be combined in the documented order"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).operators[0].properties.conditions[0].column.expressionType == "ColumnReference"
    error_message = "Filter condition column expression type should default to ColumnReference"
  }

  assert {
    condition     = jsondecode(fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens["Content"]).operators[0].id == uuidv5("x500", "CN=high-temperature")
    error_message = "Operator IDs should be derived from the operator name"
  }
}

# Test 4: A custom template file and tokens replace the generated definition
run "create_eventstream_with_custom_template" {
  command = plan

  variables {
    resource_prefix  = run.setup_tests.resource_prefix
    environment      = "test"
    fabric_workspace = run.setup_tests.fabric_workspace

    sources_custom_endpoints = [{
      name = "aio-telemetry"
    }]

    eventstream_template_file_path = "./custom/eventstream.json.tmpl"
    template_tokens = {
      "WorkspaceId" = "custom-workspace"
    }
  }

  assert {
    condition     = fabric_eventstream.rti_eventstream.definition["eventstream.json"].source == "./custom/eventstream.json.tmpl"
    error_message = "EventStream should use the provided template file"
  }

  assert {
    condition     = fabric_eventstream.rti_eventstream.definition["eventstream.json"].tokens == tomap({ "WorkspaceId" = "custom-workspace" })
    error_message = "EventStream should use the provided template tokens instead of the generated content"
  }
}
