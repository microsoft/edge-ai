provider "azurerm" {
  storage_use_azuread = true
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
    resource_prefix = run.setup_tests.resource_prefix
    resource_group  = run.setup_tests.resource_group
    location        = run.setup_tests.location
    environment     = run.setup_tests.environment
    instance        = run.setup_tests.instance
  }
}

# Test with custom parameters
run "create_custom_configuration" {
  command = plan

  variables {
    resource_prefix                      = run.setup_tests.resource_prefix
    resource_group                       = run.setup_tests.resource_group
    location                             = run.setup_tests.location
    environment                          = run.setup_tests.environment
    instance                             = run.setup_tests.instance
    storage_account_tier                 = "Premium"
    storage_account_kind                 = "BlockBlobStorage"
    storage_account_replication          = "ZRS"
    blob_soft_delete_retention_days      = 14
    container_soft_delete_retention_days = 14
    data_lake_filesystem_name            = "customdatalake"
    data_lake_blob_container_name        = "customcontainer"
    should_enable_private_endpoint       = false
  }
}

# Test with only schema registry enabled
run "create_schema_registry_only" {
  command = plan

  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    resource_group          = run.setup_tests.resource_group
    location                = run.setup_tests.location
    environment             = run.setup_tests.environment
    instance                = run.setup_tests.instance
    should_create_data_lake = false
  }

  assert {
    condition     = length(module.schema_registry) > 0
    error_message = "Schema registry should be created"
  }
}

# Test with file share enabled
run "create_with_file_share" {
  command = plan

  variables {
    resource_prefix                    = run.setup_tests.resource_prefix
    resource_group                     = run.setup_tests.resource_group
    location                           = run.setup_tests.location
    environment                        = run.setup_tests.environment
    instance                           = run.setup_tests.instance
    should_create_data_lake            = true
    should_create_data_lake_file_share = true
    file_share_name                    = "testshare"
    file_share_quota_gb                = 10
  }

  assert {
    condition     = length(module.data_lake) > 0
    error_message = "Data lake should be created"
  }
}

# Test with default ADR namespace enabled
run "create_default_adr_namespace" {
  command = plan

  variables {
    resource_prefix             = run.setup_tests.resource_prefix
    resource_group              = run.setup_tests.resource_group
    location                    = run.setup_tests.location
    environment                 = run.setup_tests.environment
    instance                    = run.setup_tests.instance
    should_create_adr_namespace = true
  }

  assert {
    condition     = length(module.adr_namespace) > 0
    error_message = "ADR namespace should be created when enabled"
  }

  assert {
    condition     = module.adr_namespace[0].adr_namespace.name == "adrns-${run.setup_tests.resource_prefix}-${run.setup_tests.environment}-${run.setup_tests.instance}"
    error_message = "ADR namespace should use default naming convention"
  }
}

# Test with custom ADR namespace configuration
run "create_custom_adr_namespace" {
  command = plan

  variables {
    resource_prefix               = run.setup_tests.resource_prefix
    resource_group                = run.setup_tests.resource_group
    location                      = run.setup_tests.location
    environment                   = run.setup_tests.environment
    instance                      = run.setup_tests.instance
    should_create_adr_namespace   = true
    adr_namespace_name            = "custom-adr-test"
    adr_namespace_enable_identity = false
    adr_namespace_messaging_endpoints = {
      "eventhub" = {
        endpointType = "EventHub"
        address      = "test.servicebus.windows.net"
        resourceId   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.EventHub/namespaces/test"
      }
    }
  }

  assert {
    condition     = length(module.adr_namespace) > 0
    error_message = "ADR namespace should be created when enabled"
  }

  assert {
    condition     = module.adr_namespace[0].adr_namespace.name == "custom-adr-test"
    error_message = "ADR namespace should use custom name when provided"
  }
}

# Test with ADR namespace disabled
run "create_without_adr_namespace" {
  command = plan

  variables {
    resource_prefix             = run.setup_tests.resource_prefix
    resource_group              = run.setup_tests.resource_group
    location                    = run.setup_tests.location
    environment                 = run.setup_tests.environment
    instance                    = run.setup_tests.instance
    should_create_adr_namespace = false
  }

  assert {
    condition     = length(module.adr_namespace) == 0
    error_message = "ADR namespace should not be created when disabled"
  }
}

# Test with a single schema deployed
run "create_with_single_schema" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    resource_group  = run.setup_tests.resource_group
    location        = run.setup_tests.location
    environment     = run.setup_tests.environment
    instance        = run.setup_tests.instance
    schemas = [
      {
        name         = "temperature-schema"
        display_name = "Temperature Schema"
        description  = "Schema for temperature sensor readings"
        format       = "JsonSchema/draft-07"
        type         = "MessageSchema"
        versions = {
          "1-0-0" = {
            description = "Initial version"
            content = jsonencode({
              "$schema" = "http://json-schema.org/draft-07/schema#"
              type      = "object"
              properties = {
                temperature = { type = "number", description = "Temperature in Celsius" }
                unit        = { type = "string", enum = ["C", "F", "K"] }
                timestamp   = { type = "string", format = "date-time" }
              }
              required = ["temperature", "unit", "timestamp"]
            })
          }
        }
      }
    ]
  }

  assert {
    condition     = length(module.schemas) > 0
    error_message = "Schemas module should be created when schemas are provided"
  }
}

# Test with multiple schemas deployed
run "create_with_multiple_schemas" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    resource_group  = run.setup_tests.resource_group
    location        = run.setup_tests.location
    environment     = run.setup_tests.environment
    instance        = run.setup_tests.instance
    schemas = [
      {
        name        = "temperature-schema"
        description = "Schema for temperature sensor readings"
        versions = {
          "1-0-0" = {
            description = "Initial version"
            content = jsonencode({
              "$schema" = "http://json-schema.org/draft-07/schema#"
              type      = "object"
              properties = {
                temperature = { type = "number" }
                unit        = { type = "string", enum = ["C", "F", "K"] }
                timestamp   = { type = "string", format = "date-time" }
              }
              required = ["temperature", "unit", "timestamp"]
            })
          }
          "1-1-0" = {
            description = "Added optional sensor ID field"
            content = jsonencode({
              "$schema" = "http://json-schema.org/draft-07/schema#"
              type      = "object"
              properties = {
                temperature = { type = "number" }
                unit        = { type = "string", enum = ["C", "F", "K"] }
                timestamp   = { type = "string", format = "date-time" }
                sensor_id   = { type = "string" }
              }
              required = ["temperature", "unit", "timestamp"]
            })
          }
        }
      },
      {
        name        = "pressure-schema"
        description = "Schema for pressure sensor readings"
        versions = {
          "1-0-0" = {
            description = "Initial version"
            content = jsonencode({
              "$schema" = "http://json-schema.org/draft-07/schema#"
              type      = "object"
              properties = {
                pressure  = { type = "number", description = "Pressure in hPa" }
                timestamp = { type = "string", format = "date-time" }
              }
              required = ["pressure", "timestamp"]
            })
          }
        }
      }
    ]
  }

  assert {
    condition     = length(module.schemas) > 0
    error_message = "Schemas module should be created when multiple schemas are provided"
  }
}

# Test ADR namespace with minimal messaging endpoints
run "create_adr_namespace_with_minimal_endpoints" {
  command = plan

  variables {
    resource_prefix             = run.setup_tests.resource_prefix
    resource_group              = run.setup_tests.resource_group
    location                    = run.setup_tests.location
    environment                 = run.setup_tests.environment
    instance                    = run.setup_tests.instance
    should_create_adr_namespace = true
    adr_namespace_messaging_endpoints = {
      "mqtt" = {
        endpointType = "MQTT"
        address      = "mqtt://test.local:1883"
      }
    }
  }

  assert {
    condition     = length(module.adr_namespace) > 0
    error_message = "ADR namespace should be created with minimal messaging endpoints"
  }
}
