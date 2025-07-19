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

# Test Event Hub naming conventions
run "verify_eventhub_configuration" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_eventhub  = true
    should_create_eventgrid = false

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

  # Verify the Event Hub namespace name follows the correct pattern
  assert {
    condition     = module.eventhub[0].eventhub_namespace.name == "evhns-testpre-aio-test-001"
    error_message = "Event Hub namespace should follow the naming pattern 'evhns-{resource_prefix}-aio-{environment}-{instance}'"
  }
}

# Test Event Grid naming conventions
run "verify_eventgrid_naming" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_eventhub  = false
    should_create_eventgrid = true
  }

  # Check that the endpoint follows the correct pattern
  assert {
    condition     = can(regex("evgns-testpre-test-aio-002.*", module.eventgrid[0].eventgrid.endpoint))
    error_message = "Event Grid endpoint should contain the namespace name matching pattern 'evgns-{resource_prefix}-{environment}-aio-{instance}'"
  }
}

# Test Azure Functions naming conventions
run "verify_azure_functions_naming" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  # Verify the App Service Plan module is created
  assert {
    condition     = length(module.app_service_plan) == 1
    error_message = "The App Service Plan module should be created"
  }

  # Verify the Azure Functions module is created
  assert {
    condition     = length(module.azure_functions) == 1
    error_message = "The Azure Functions module should be created"
  }

  # Verify the App Service Plan name follows the correct pattern
  assert {
    condition     = module.app_service_plan[0].app_service_plan.name == "asp-testpre-test-003"
    error_message = "App Service Plan should follow the naming pattern 'asp-{resource_prefix}-{environment}-{instance}'"
  }

  # Verify the Function App name follows the correct pattern
  assert {
    condition     = module.azure_functions[0].function_app.name == "func-testpre-test-003"
    error_message = "Function App should follow the naming pattern 'func-{resource_prefix}-{environment}-{instance}'"
  }

  # Verify the Storage Account name follows the correct pattern
  assert {
    condition     = module.azure_functions[0].storage_account.name == "sttestpretestfn003"
    error_message = "Storage Account should follow the naming pattern 'st{resource_prefix}{environment}fn{instance}'"
  }
}
