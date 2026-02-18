provider "azurerm" {
  features {}
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test with default parameters
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = run.setup_tests.environment
    instance             = run.setup_tests.instance
    aio_identity         = run.setup_tests.aio_identity
    aio_custom_locations = run.setup_tests.aio_custom_locations
    aio_instance         = run.setup_tests.aio_instance
    aio_dataflow_profile = run.setup_tests.aio_dataflow_profile
    eventhub             = run.setup_tests.eventhub
    eventgrid            = run.setup_tests.eventgrid
  }

  assert {
    condition     = length(module.sample_eventhub_dataflow) > 0
    error_message = "EventHub dataflow should be created by default"
  }

  assert {
    condition     = length(module.sample_eventgrid_dataflow) > 0
    error_message = "EventGrid dataflow should be created by default"
  }

  assert {
    condition     = length(module.sample_fabric_rti_dataflow) == 0
    error_message = "Fabric RTI dataflow should not be created by default"
  }

  assert {
    condition     = length(module.dataflow_graphs) == 0
    error_message = "Dataflow graphs should not be created by default"
  }
}

# Test with all dataflows disabled
run "create_all_disabled" {
  command = plan

  variables {
    resource_prefix                    = run.setup_tests.resource_prefix
    environment                        = run.setup_tests.environment
    instance                           = run.setup_tests.instance
    aio_identity                       = run.setup_tests.aio_identity
    aio_custom_locations               = run.setup_tests.aio_custom_locations
    aio_instance                       = run.setup_tests.aio_instance
    aio_dataflow_profile               = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows   = false
    should_create_eventgrid_dataflows  = false
    should_create_fabric_rti_dataflows = false
  }

  assert {
    condition     = length(module.sample_eventhub_dataflow) == 0
    error_message = "EventHub dataflow should not be created when disabled"
  }

  assert {
    condition     = length(module.sample_eventgrid_dataflow) == 0
    error_message = "EventGrid dataflow should not be created when disabled"
  }

  assert {
    condition     = length(module.sample_fabric_rti_dataflow) == 0
    error_message = "Fabric RTI dataflow should not be created when disabled"
  }

  assert {
    condition     = length(module.dataflow_graphs) == 0
    error_message = "Dataflow graphs should not be created when disabled"
  }
}

# Test with only EventHub dataflow enabled
run "create_eventhub_only" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    eventhub                          = run.setup_tests.eventhub
    should_create_eventhub_dataflows  = true
    should_create_eventgrid_dataflows = false
  }

  assert {
    condition     = length(module.sample_eventhub_dataflow) > 0
    error_message = "EventHub dataflow should be created when enabled"
  }

  assert {
    condition     = length(module.sample_eventgrid_dataflow) == 0
    error_message = "EventGrid dataflow should not be created when disabled"
  }
}

# Test with only EventGrid dataflow enabled
run "create_eventgrid_only" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    eventgrid                         = run.setup_tests.eventgrid
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = true
  }

  assert {
    condition     = length(module.sample_eventhub_dataflow) == 0
    error_message = "EventHub dataflow should not be created when disabled"
  }

  assert {
    condition     = length(module.sample_eventgrid_dataflow) > 0
    error_message = "EventGrid dataflow should be created when enabled"
  }
}

# Test with dataflow graphs enabled
run "create_with_dataflow_graphs" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = run.setup_tests.environment
    instance             = run.setup_tests.instance
    aio_identity         = run.setup_tests.aio_identity
    aio_custom_locations = run.setup_tests.aio_custom_locations
    aio_instance         = run.setup_tests.aio_instance
    aio_dataflow_profile = run.setup_tests.aio_dataflow_profile
    eventhub             = run.setup_tests.eventhub
    eventgrid            = run.setup_tests.eventgrid
    dataflow_graphs = [
      {
        name = "temperature-processing"
        nodes = [
          {
            nodeType = "Source"
            name     = "temperature-source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["raw"]
            }
          },
          {
            nodeType = "Graph"
            name     = "temperature-map-custom"
            graphSettings = {
              registryEndpointRef = "acr-wasm"
              artifact            = "graph-simple-map-custom:1.0.0"
            }
          },
          {
            nodeType = "Destination"
            name     = "temperature-destination"
            destinationSettings = {
              endpointRef     = "default"
              dataDestination = "processed"
            }
          }
        ]
        node_connections = [
          {
            from = { name = "temperature-source" }
            to   = { name = "temperature-map-custom" }
          },
          {
            from = { name = "temperature-map-custom" }
            to   = { name = "temperature-destination" }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_graphs) > 0
    error_message = "Dataflow graphs should be created when enabled"
  }
}

# Test with dataflow graphs enabled but empty list
run "create_with_empty_dataflow_graphs" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = run.setup_tests.environment
    instance             = run.setup_tests.instance
    aio_identity         = run.setup_tests.aio_identity
    aio_custom_locations = run.setup_tests.aio_custom_locations
    aio_instance         = run.setup_tests.aio_instance
    aio_dataflow_profile = run.setup_tests.aio_dataflow_profile
    eventhub             = run.setup_tests.eventhub
    eventgrid            = run.setup_tests.eventgrid
    dataflow_graphs      = []
  }

  assert {
    condition     = length(module.dataflow_graphs) == 0
    error_message = "Dataflow graphs module should not be created with an empty list"
  }
}

# Test with multiple dataflow graphs
run "create_with_multiple_dataflow_graphs" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = run.setup_tests.environment
    instance             = run.setup_tests.instance
    aio_identity         = run.setup_tests.aio_identity
    aio_custom_locations = run.setup_tests.aio_custom_locations
    aio_instance         = run.setup_tests.aio_instance
    aio_dataflow_profile = run.setup_tests.aio_dataflow_profile
    eventhub             = run.setup_tests.eventhub
    eventgrid            = run.setup_tests.eventgrid
    dataflow_graphs = [
      {
        name                     = "graph-one"
        mode                     = "Enabled"
        request_disk_persistence = "Disabled"
        nodes = [
          {
            nodeType = "Source"
            name     = "graph-one-source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["raw"]
            }
          },
          {
            nodeType = "Graph"
            name     = "graph-one-processor"
            graphSettings = {
              registryEndpointRef = "acr-wasm"
              artifact            = "graph-simple-map-custom:1.0.0"
            }
          },
          {
            nodeType = "Destination"
            name     = "graph-one-destination"
            destinationSettings = {
              endpointRef     = "default"
              dataDestination = "processed-one"
            }
          }
        ]
        node_connections = [
          {
            from = { name = "graph-one-source" }
            to   = { name = "graph-one-processor" }
          },
          {
            from = { name = "graph-one-processor" }
            to   = { name = "graph-one-destination" }
          }
        ]
      },
      {
        name                     = "graph-two"
        mode                     = "Disabled"
        request_disk_persistence = "Enabled"
        nodes = [
          {
            nodeType = "Source"
            name     = "graph-two-source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["metrics"]
            }
          },
          {
            nodeType = "Graph"
            name     = "graph-two-processor"
            graphSettings = {
              registryEndpointRef = "acr-wasm"
              artifact            = "graph-simple-map-custom:1.0.0"
            }
          },
          {
            nodeType = "Destination"
            name     = "graph-two-destination"
            destinationSettings = {
              endpointRef     = "default"
              dataDestination = "processed-two"
            }
          }
        ]
        node_connections = [
          {
            from = { name = "graph-two-source" }
            to   = { name = "graph-two-processor" }
          },
          {
            from = { name = "graph-two-processor" }
            to   = { name = "graph-two-destination" }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_graphs) > 0
    error_message = "Dataflow graphs module should be created with multiple graphs"
  }
}

# Test with custom asset name
run "create_with_custom_asset_name" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = run.setup_tests.environment
    instance             = run.setup_tests.instance
    aio_identity         = run.setup_tests.aio_identity
    aio_custom_locations = run.setup_tests.aio_custom_locations
    aio_instance         = run.setup_tests.aio_instance
    aio_dataflow_profile = run.setup_tests.aio_dataflow_profile
    eventhub             = run.setup_tests.eventhub
    eventgrid            = run.setup_tests.eventgrid
    asset_name           = "custom-sensor-asset"
  }

  assert {
    condition     = length(module.sample_eventhub_dataflow) > 0
    error_message = "EventHub dataflow should be created with custom asset name"
  }
}
