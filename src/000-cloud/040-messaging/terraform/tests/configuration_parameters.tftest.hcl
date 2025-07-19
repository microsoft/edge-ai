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

# Test Event Hub configuration parameters
run "verify_eventhub_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_eventhub  = true
    should_create_eventgrid = false
  }

  # Verify the Event Hub namespace is configured with the default capacity and Standard SKU
  assert {
    condition     = module.eventhub[0].eventhub_namespace.capacity == 1
    error_message = "Event Hub namespace should be configured with default capacity of 1"
  }

  assert {
    condition     = module.eventhub[0].eventhub_namespace.sku == "Standard"
    error_message = "Event Hub namespace should be configured with Standard SKU"
  }

  # Verify the Event Hub is configured with the default partition count and message retention
  assert {
    condition     = length(module.eventhub[0].eventhubs) > 0 && module.eventhub[0].eventhubs[0].partition_count == 1
    error_message = "Event Hub should be configured with default partition count of 1"
  }

  assert {
    condition     = length(module.eventhub[0].eventhubs) > 0 && module.eventhub[0].eventhubs[0].message_retention == 1
    error_message = "Event Hub should be configured with default message retention of 1 day"
  }
}

# Test Event Grid configuration parameters
run "verify_eventgrid_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_eventhub  = false
    should_create_eventgrid = true
  }

  # Verify Event Grid is created
  assert {
    condition     = contains(keys(module.eventgrid[0]), "eventgrid")
    error_message = "Event Grid should be created with default configuration"
  }

  # Verify Event Grid namespace is configured with the default capacity and Standard SKU
  assert {
    condition     = module.eventgrid[0].eventgrid.capacity == 1
    error_message = "Event Grid namespace should be configured with default capacity of 1"
  }

  assert {
    condition     = module.eventgrid[0].eventgrid.sku == "Standard"
    error_message = "Event Grid namespace should be configured with Standard SKU"
  }

  # Verify Event Grid is configured with the default client sessions
  assert {
    condition     = module.eventgrid[0].eventgrid.max_client_sessions_per_auth == 8
    error_message = "Event Grid namespace should be configured with default maximum_client_sessions_per_authentication_name of 8"
  }

  # Verify Event Grid has the default topic name
  assert {
    condition     = module.eventgrid[0].eventgrid.topic_name == "default"
    error_message = "Event Grid should have the default topic name 'default'"
  }

  # Verify Event Grid namespace follows the correct naming pattern
  assert {
    condition     = startswith(module.eventgrid[0].eventgrid.namespace_name, "evgns-")
    error_message = "Event Grid namespace name should start with 'evgns-'"
  }

  # Verify Event Grid topic space follows the correct naming pattern
  assert {
    condition     = startswith(module.eventgrid[0].eventgrid.topic_space_name, "evgts-")
    error_message = "Event Grid topic space name should start with 'evgts-'"
  }
}

# Test Event Hub with custom configuration parameters
run "verify_custom_eventhub_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_eventhub  = true
    should_create_eventgrid = false

    # These will override the defaults in the main module
    eventhub_capacity = 2
    eventhubs = {
      "01" = {}
      "02" = {
        message_retention = 2
        partition_count   = 2
        consumer_groups = {
          "a" = {}
          "b" = {
            user_metadata = "test"
          }
        }
      }
    }
  }

  # Verify an Event Hub module is created
  assert {
    condition     = length(module.eventhub) == 1
    error_message = "There should be one Event Hub module created"
  }

  # Verify the custom capacity is passed to the module
  assert {
    condition     = module.eventhub[0].eventhub_namespace.capacity == var.eventhub_capacity
    error_message = "Event Hub capacity should be set to custom value ${var.eventhub_capacity}"
  }

  # Verify both custom EHs are listed
  assert {
    condition     = length(module.eventhub[0].eventhubs) == 2
    error_message = "There should be two Event Hubs created within the namespace"
  }

  # Verify the custom message retention is passed to the module
  assert {
    condition     = length(module.eventhub[0].eventhubs) == 2 && module.eventhub[0].eventhubs[0].message_retention == var.eventhubs["01"].message_retention && module.eventhub[0].eventhubs[1].message_retention == var.eventhubs["02"].message_retention
    error_message = "Event Hub message_retention should be set correctly for both event hubs"
  }

  # Verify the custom partition count is passed to the module
  assert {
    condition     = length(module.eventhub[0].eventhubs) == 2 && module.eventhub[0].eventhubs[0].partition_count == var.eventhubs["01"].partition_count && module.eventhub[0].eventhubs[1].partition_count == var.eventhubs["02"].partition_count
    error_message = "Event Hub partition_count should be set correctly for both event hubs"
  }

  # Verify that consumer groups are listed in the second event hub
  assert {
    condition     = length(module.eventhub[0].eventhubs) == 2 && length(module.eventhub[0].eventhubs[1].consumer_groups) == 2
    error_message = "There should be two consumer groups created in the second event hub"
  }

  # Verify that consumer groups have the correct metadata
  assert {
    condition     = length(module.eventhub[0].eventhubs) == 2 && length(module.eventhub[0].eventhubs[1].consumer_groups) == 2 && module.eventhub[0].eventhubs[1].consumer_groups[1].user_metadata == "test"
    error_message = "Consumer group should have custom metadata 'test'"
  }
}

# Test Event Grid with custom configuration parameters
run "verify_custom_eventgrid_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    should_create_eventhub  = false
    should_create_eventgrid = true

    eventgrid_capacity            = 2
    eventgrid_max_client_sessions = 6
    eventgrid_topic_name          = "custom-topic"
  }

  # Verify an Event Grid module is created
  assert {
    condition     = length(module.eventgrid) == 1
    error_message = "There should be one Event Grid module created"
  }

  # Verify the custom capacity is passed to the module
  assert {
    condition     = module.eventgrid[0].eventgrid.capacity == var.eventgrid_capacity
    error_message = "Event Grid capacity should be set to custom value ${var.eventgrid_capacity}"
  }

  # Verify the custom max client sessions value is passed to the module
  assert {
    condition     = module.eventgrid[0].eventgrid.max_client_sessions_per_auth == var.eventgrid_max_client_sessions
    error_message = "Event Grid max client sessions should be set to custom value ${var.eventgrid_max_client_sessions}"
  }

  assert {
    condition     = module.eventgrid[0].eventgrid.max_client_sessions_per_auth <= 8
    error_message = "Event Grid max client sessions should be set custom value  less than 8"
  }

  # Verify the custom topic name is passed to the module
  assert {
    condition     = module.eventgrid[0].eventgrid.topic_name == var.eventgrid_topic_name
    error_message = "Event Grid topic name should be set to custom value ${var.eventgrid_topic_name}"
  }
}

# Test Azure Functions configuration parameters
run "verify_azure_functions_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "004"

    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  # Verify the App Service Plan has been created
  assert {
    condition     = contains(keys(module.app_service_plan[0]), "app_service_plan")
    error_message = "App Service Plan should be created with default configuration"
  }

  # Verify the Azure Functions has been created
  assert {
    condition     = contains(keys(module.azure_functions[0]), "function_app")
    error_message = "Azure Functions should be created with default configuration"
  }

  # Verify the App Service Plan is configured with default OS type and SKU
  assert {
    condition     = module.app_service_plan[0].app_service_plan.os_type == "Linux"
    error_message = "App Service Plan should be configured with default OS type of Linux"
  }

  assert {
    condition     = module.app_service_plan[0].app_service_plan.sku_name == "B1"
    error_message = "App Service Plan should be configured with default SKU of B1"
  }

  # Verify the Function App is configured with default node version
  assert {
    condition     = module.azure_functions[0].function_app.os_type == "Linux"
    error_message = "Function App should be configured with Linux OS type matching the App Service Plan"
  }
}

# Test Azure Functions with custom configuration parameters
run "verify_custom_azure_functions_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "005"

    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false

    # These will override the defaults in the main module
    app_service_plan_os_type  = "Windows"
    app_service_plan_sku_name = "EP1"
    function_node_version     = "~20"
    function_app_settings = {
      "CUSTOM_SETTING" = "test_value"
    }
    function_cors_allowed_origins     = ["https://example.com"]
    function_cors_support_credentials = true
  }

  # Verify an App Service Plan module is created
  assert {
    condition     = length(module.app_service_plan) == 1
    error_message = "There should be one App Service Plan module created"
  }

  # Verify an Azure Functions module is created
  assert {
    condition     = length(module.azure_functions) == 1
    error_message = "There should be one Azure Functions module created"
  }

  # Verify the custom OS type is passed to the module
  assert {
    condition     = module.app_service_plan[0].app_service_plan.os_type == var.app_service_plan_os_type
    error_message = "App Service Plan OS type should be set to custom value ${var.app_service_plan_os_type}"
  }

  # Verify the custom SKU name is passed to the module
  assert {
    condition     = module.app_service_plan[0].app_service_plan.sku_name == var.app_service_plan_sku_name
    error_message = "App Service Plan SKU name should be set to custom value ${var.app_service_plan_sku_name}"
  }

  # Verify the Function App OS type matches the App Service Plan
  assert {
    condition     = module.azure_functions[0].function_app.os_type == var.app_service_plan_os_type
    error_message = "Function App OS type should match App Service Plan OS type ${var.app_service_plan_os_type}"
  }
}
