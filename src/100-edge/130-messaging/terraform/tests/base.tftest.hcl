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

  assert {
    condition     = length(module.dataflows) == 0
    error_message = "Dataflows should not be created by default"
  }

  assert {
    condition     = length(module.dataflow_endpoints) == 0
    error_message = "Dataflow endpoints should not be created by default"
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

  assert {
    condition     = length(module.dataflows) == 0
    error_message = "Dataflows should not be created when disabled"
  }

  assert {
    condition     = length(module.dataflow_endpoints) == 0
    error_message = "Dataflow endpoints should not be created when disabled"
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

# Test with a simple dataflow (source to destination)
run "create_with_simple_dataflow" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflows = [
      {
        name = "aio-to-event-grid"
        operations = [
          {
            operationType = "Source"
            name          = "aio-source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["azure-iot-operations/data/thermostat"]
            }
          },
          {
            operationType = "Destination"
            name          = "event-grid-destination"
            destinationSettings = {
              endpointRef     = "event-grid-endpoint"
              dataDestination = "telemetry/aio"
            }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflows) > 0
    error_message = "Dataflows module should be created with dataflows"
  }
}

# Test with a dataflow including built-in transformation
run "create_with_transformation_dataflow" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflows = [
      {
        name                     = "aio-to-event-hub-transformed"
        mode                     = "Enabled"
        request_disk_persistence = "Enabled"
        operations = [
          {
            operationType = "Source"
            name          = "aio-source"
            sourceSettings = {
              endpointRef         = "default"
              serializationFormat = "Json"
              dataSources         = ["azure-iot-operations/data/thermostat"]
            }
          },
          {
            operationType = "BuiltInTransformation"
            name          = "transform"
            builtInTransformationSettings = {
              filter = [
                {
                  inputs     = ["temperature.value"]
                  expression = "$1 > 20"
                }
              ]
              map = [
                {
                  inputs = ["temperature.value"]
                  output = "payload.temperature"
                },
                {
                  inputs     = ["*"]
                  expression = ""
                  output     = "payload.raw"
                }
              ]
            }
          },
          {
            operationType = "Destination"
            name          = "event-hub-destination"
            destinationSettings = {
              endpointRef     = "event-hub-endpoint"
              dataDestination = "telemetry"
            }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflows) > 0
    error_message = "Dataflows module should be created with transformation dataflow"
  }
}

# Test with multiple dataflows
run "create_with_multiple_dataflows" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflows = [
      {
        name = "dataflow-one"
        operations = [
          {
            operationType = "Source"
            name          = "source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["raw"]
            }
          },
          {
            operationType = "Destination"
            name          = "destination"
            destinationSettings = {
              endpointRef     = "endpoint-one"
              dataDestination = "topic-one"
            }
          }
        ]
      },
      {
        name                     = "dataflow-two"
        mode                     = "Disabled"
        request_disk_persistence = "Enabled"
        operations = [
          {
            operationType = "Source"
            name          = "source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["metrics"]
            }
          },
          {
            operationType = "Destination"
            name          = "destination"
            destinationSettings = {
              endpointRef     = "endpoint-two"
              dataDestination = "topic-two"
            }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflows) > 0
    error_message = "Dataflows module should be created with multiple dataflows"
  }
}

# Test with empty dataflows list
run "create_with_empty_dataflows" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflows                         = []
  }

  assert {
    condition     = length(module.dataflows) == 0
    error_message = "Dataflows module should not be created with an empty list"
  }
}

# Test with a Kafka dataflow endpoint
run "create_with_kafka_endpoint" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "event-hub-endpoint"
        endpointType = "Kafka"
        hostType     = "Eventhub"
        kafkaSettings = {
          host = "example.servicebus.windows.net:9093"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
          tls = {
            mode = "Enabled"
          }
          consumerGroupId = "aiodataflows"
        }
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created with Kafka endpoint"
  }
}

# Test with an MQTT dataflow endpoint
run "create_with_mqtt_endpoint" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "event-grid-mqtt"
        endpointType = "Mqtt"
        hostType     = "EventGrid"
        mqttSettings = {
          host = "example.westeurope-1.ts.eventgrid.azure.net:8883"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
          tls = {
            mode = "Enabled"
          }
        }
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created with MQTT endpoint"
  }
}

# Test with multiple dataflow endpoint types
run "create_with_multiple_endpoint_types" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "kafka-endpoint"
        endpointType = "Kafka"
        kafkaSettings = {
          host = "example.servicebus.windows.net:9093"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
        }
      },
      {
        name         = "adx-endpoint"
        endpointType = "DataExplorer"
        dataExplorerSettings = {
          host     = "example.westeurope.kusto.windows.net"
          database = "telemetry"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
        }
      },
      {
        name         = "local-storage"
        endpointType = "LocalStorage"
        localStorageSettings = {
          persistentVolumeClaimRef = "example-pvc"
        }
      },
      {
        name         = "fabric-endpoint"
        endpointType = "FabricOneLake"
        fabricOneLakeSettings = {
          host = "onelake.dfs.fabric.microsoft.com"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
          names = {
            workspaceName = "test-workspace"
            lakehouseName = "test-lakehouse"
          }
          oneLakePathType = "Tables"
        }
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created with multiple endpoint types"
  }
}

# Test with empty dataflow endpoints list
run "create_with_empty_dataflow_endpoints" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints                = []
  }

  assert {
    condition     = length(module.dataflow_endpoints) == 0
    error_message = "Dataflow endpoints module should not be created with an empty list"
  }
}

# Test with DataLakeStorage endpoint
run "create_with_datalake_endpoint" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "datalake-endpoint"
        endpointType = "DataLakeStorage"
        dataLakeStorageSettings = {
          host = "example.blob.core.windows.net"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
          batching = {
            latencySeconds = 60
            maxMessages    = 100000
          }
        }
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created with DataLakeStorage endpoint"
  }
}

# Test with OpenTelemetry endpoint
run "create_with_otel_endpoint" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "otel-endpoint"
        endpointType = "OpenTelemetry"
        openTelemetrySettings = {
          host = "otel-collector.observability.svc.cluster.local:4317"
          authentication = {
            method            = "Anonymous"
            anonymousSettings = {}
          }
        }
      }
    ]
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created with OpenTelemetry endpoint"
  }
}

# Test with dataflows and dataflow endpoints together
run "create_with_dataflows_and_endpoints" {
  command = plan

  variables {
    resource_prefix                   = run.setup_tests.resource_prefix
    environment                       = run.setup_tests.environment
    instance                          = run.setup_tests.instance
    aio_identity                      = run.setup_tests.aio_identity
    aio_custom_locations              = run.setup_tests.aio_custom_locations
    aio_instance                      = run.setup_tests.aio_instance
    aio_dataflow_profile              = run.setup_tests.aio_dataflow_profile
    should_create_eventhub_dataflows  = false
    should_create_eventgrid_dataflows = false
    dataflow_endpoints = [
      {
        name         = "mqtt-endpoint"
        endpointType = "Mqtt"
        mqttSettings = {
          host = "broker.example.com:8883"
          authentication = {
            method                                = "SystemAssignedManagedIdentity"
            systemAssignedManagedIdentitySettings = {}
          }
        }
      }
    ]
    dataflows = [
      {
        name = "broker-to-mqtt"
        operations = [
          {
            operationType = "Source"
            name          = "source"
            sourceSettings = {
              endpointRef = "default"
              dataSources = ["telemetry/#"]
            }
          },
          {
            operationType = "Destination"
            name          = "destination"
            destinationSettings = {
              endpointRef     = "mqtt-endpoint"
              dataDestination = "remote/telemetry"
            }
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(module.dataflows) > 0
    error_message = "Dataflows module should be created"
  }

  assert {
    condition     = length(module.dataflow_endpoints) > 0
    error_message = "Dataflow endpoints module should be created"
  }
}
