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

run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"
  }

  assert {
    condition     = module.eventhub[0].eventhub_namespace != null && module.eventhub[0].eventhubs != null
    error_message = "Event Hub should be created"
  }

  assert {
    condition     = module.eventgrid[0].eventgrid != null
    error_message = "Event Grid should be created"
  }

  assert {
    condition     = length(module.app_service_plan) == 0
    error_message = "App Service Plan should not be created when should_create_azure_functions is false"
  }

  assert {
    condition     = length(module.azure_functions) == 0
    error_message = "Azure Functions should not be created when should_create_azure_functions is false"
  }

  assert {
    condition     = length(module.app_service_plan) == 0
    error_message = "App Service Plan should not be created when should_create_azure_functions is false"
  }

  assert {
    condition     = length(module.azure_functions) == 0
    error_message = "Azure Functions should not be created when should_create_azure_functions is false"
  }
}

run "verify_eventhub_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    # Only create Event Hubs
    should_create_eventhub  = true
    should_create_eventgrid = false
  }

  assert {
    condition     = module.eventhub[0].eventhub_namespace != null && module.eventhub[0].eventhubs != null
    error_message = "Event Hub should be created"
  }

  assert {
    condition     = length(module.eventgrid) == 0
    error_message = "Event Grid should not be created"
  }
}

run "create_only_eventgrid" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    # Only create Event Grid
    should_create_eventhub  = false
    should_create_eventgrid = true
  }

  assert {
    condition     = module.eventgrid[0].eventgrid != null
    error_message = "Event Grid should be created"
  }

  assert {
    condition     = length(module.eventhub) == 0
    error_message = "Event Hub should not be created"
  }
}

run "create_no_messaging" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    # Create none of the services
    should_create_azure_functions = false
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  assert {
    condition     = length(module.app_service_plan) == 0
    error_message = "App Service Plan should not be created"
  }

  assert {
    condition     = length(module.azure_functions) == 0
    error_message = "Azure Functions should not be created"
  }

  assert {
    condition     = length(module.eventhub) == 0
    error_message = "Event Hub should not be created"
  }

  assert {
    condition     = length(module.eventgrid) == 0
    error_message = "Event Grid should not be created"
  }
}

run "create_only_azure_functions" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "004"

    # Only create Azure Functions
    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  assert {
    condition     = module.app_service_plan[0].app_service_plan != null
    error_message = "App Service Plan should be created"
  }

  assert {
    condition     = module.azure_functions[0].function_app != null
    error_message = "Azure Functions should be created"
  }

  assert {
    condition     = length(module.eventhub) == 0
    error_message = "Event Hub should not be created"
  }

  assert {
    condition     = length(module.eventgrid) == 0
    error_message = "Event Grid should not be created"
  }
}

run "create_functions_and_eventhub" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "005"

    # Create Azure Functions and Event Hub
    should_create_azure_functions = true
    should_create_eventhub        = true
    should_create_eventgrid       = false
  }

  assert {
    condition     = module.app_service_plan[0].app_service_plan != null
    error_message = "App Service Plan should be created"
  }

  assert {
    condition     = module.azure_functions[0].function_app != null
    error_message = "Azure Functions should be created"
  }

  assert {
    condition     = module.eventhub[0].eventhubs != null
    error_message = "Event Hub should be created"
  }

  assert {
    condition     = length(module.eventgrid) == 0
    error_message = "Event Grid should not be created"
  }
}

run "create_all_services" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "006"

    # Create all services
    should_create_azure_functions = true
    should_create_eventhub        = true
    should_create_eventgrid       = true
  }

  assert {
    condition     = module.app_service_plan[0].app_service_plan != null
    error_message = "App Service Plan should be created"
  }

  assert {
    condition     = module.azure_functions[0].function_app != null
    error_message = "Azure Functions should be created"
  }

  assert {
    condition     = module.eventhub[0].eventhubs != null
    error_message = "Event Hub should be created"
  }

  assert {
    condition     = module.eventgrid[0].eventgrid != null
    error_message = "Event Grid should be created"
  }
}
