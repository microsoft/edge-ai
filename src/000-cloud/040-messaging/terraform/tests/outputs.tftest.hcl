mock_provider "azurerm" {
  override_resource {
    target = azurerm_resource_group.this
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      name     = "test-rg"
      location = "eastus"
    }
  }

  override_resource {
    target = module.app_service_plan[0].azurerm_service_plan.app_service_plan
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Web/serverFarms/asp-testpre-test-005"
      name     = "asp-testpre-test-005"
      location = "eastus"
      os_type  = "Linux"
      sku_name = "B1"
    }
  }

  override_resource {
    target = module.azure_functions[0].azurerm_storage_account.function_storage
    values = {
      id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/sttestpretestfn005"
      name                  = "sttestpretestfn005"
      location              = "eastus"
      primary_access_key    = "mock-key"
      primary_blob_endpoint = "https://sttestpretestfn005.blob.core.windows.net/"
    }
  }

  override_resource {
    target = module.azure_functions[0].azurerm_linux_function_app.function_app[0]
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Web/sites/func-testpre-test-005"
      name     = "func-testpre-test-005"
      location = "eastus"
    }
  }
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test outputs when both Event Hub and Event Grid are created
run "verify_outputs_both_services" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_event_hubs = true
    should_create_event_grid = true
  }

  # Verify the Event Hub output is correctly set
  assert {
    condition     = output.event_hub != null
    error_message = "Event Hub output should be defined when should_create_event_hubs is true"
  }

  assert {
    condition     = output.event_hub.namespace_name == "evhns-testpre-aio-test-001"
    error_message = "Event Hub output should include the correct namespace_name"
  }

  assert {
    condition     = output.event_hub.event_hub_name == "evh-testpre-aio-test-001"
    error_message = "Event Hub output should include the correct event_hub_name"
  }

  # Verify the Event Grid outputs are correctly set
  assert {
    condition     = output.event_grid != null
    error_message = "Event Grid output should be defined when should_create_event_grid is true"
  }

  assert {
    condition     = output.event_grid.topic_name == "default"
    error_message = "Event Grid output should include the default topic_name"
  }

  assert {
    condition     = output.event_grid_endpoint != null
    error_message = "Event Grid endpoint output should be defined when should_create_event_grid is true"
  }

  assert {
    condition     = output.event_grid_endpoint == "evgns-testpre-test-aio-001.${var.resource_group.location}-1.ts.eventgrid.azure.net:8883"
    error_message = "Event Grid endpoint output should have the correct format"
  }
}

# Test outputs when only Event Hub is created
run "verify_outputs_only_event_hub" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_event_hubs = true
    should_create_event_grid = false
  }

  # Verify the Event Hub output is correctly set
  assert {
    condition     = output.event_hub != null
    error_message = "Event Hub output should be defined when should_create_event_hubs is true"
  }

  # Verify the Event Grid outputs are null
  assert {
    condition     = output.event_grid == null
    error_message = "Event Grid output should be null when should_create_event_grid is false"
  }

  assert {
    condition     = output.event_grid_endpoint == null
    error_message = "Event Grid endpoint output should be null when should_create_event_grid is false"
  }
}

# Test outputs when only Event Grid is created
run "verify_outputs_only_event_grid" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    should_create_event_hubs = false
    should_create_event_grid = true
  }

  # Verify the Event Hub output is null
  assert {
    condition     = output.event_hub == null
    error_message = "Event Hub output should be null when should_create_event_hubs is false"
  }

  # Verify the Event Grid outputs are correctly set
  assert {
    condition     = output.event_grid != null
    error_message = "Event Grid output should be defined when should_create_event_grid is true"
  }

  assert {
    condition     = output.event_grid_endpoint != null
    error_message = "Event Grid endpoint output should be defined when should_create_event_grid is true"
  }
}

# Test outputs when neither service is created
run "verify_outputs_no_services" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "004"

    should_create_event_hubs = false
    should_create_event_grid = false
  }

  # Verify all outputs are null
  assert {
    condition     = output.event_hub == null
    error_message = "Event Hub output should be null when should_create_event_hubs is false"
  }

  assert {
    condition     = output.event_grid == null
    error_message = "Event Grid output should be null when should_create_event_grid is false"
  }

  assert {
    condition     = output.event_grid_endpoint == null
    error_message = "Event Grid endpoint output should be null when should_create_event_grid is false"
  }
}

# Test outputs when Azure Functions is created
run "verify_outputs_azure_functions" {
  command = apply

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "005"

    should_create_azure_functions = true
    should_create_event_hubs      = false
    should_create_event_grid      = false
  }

  # Verify the App Service Plan output is correctly set
  assert {
    condition     = output.app_service_plan != null
    error_message = "App Service Plan output should be defined when should_create_azure_functions is true"
  }

  assert {
    condition     = output.app_service_plan.name == "asp-testpre-test-005"
    error_message = "App Service Plan output should include the correct name"
  }

  assert {
    condition     = output.app_service_plan.os_type == "Linux"
    error_message = "App Service Plan output should include the correct os_type"
  }

  assert {
    condition     = output.app_service_plan.sku_name == "B1"
    error_message = "App Service Plan output should include the correct sku_name"
  }

  # Verify the Function App output is correctly set
  assert {
    condition     = output.function_app != null
    error_message = "Function App output should be defined when should_create_azure_functions is true"
  }

  assert {
    condition     = output.function_app.name == "func-testpre-test-005"
    error_message = "Function App output should include the correct name"
  }

  assert {
    condition     = output.function_app.os_type == "Linux"
    error_message = "Function App output should include the correct os_type"
  }

  # Verify the Function Storage Account output is correctly set
  assert {
    condition     = output.function_storage_account != null
    error_message = "Function Storage Account output should be defined when should_create_azure_functions is true"
  }

  assert {
    condition     = output.function_storage_account.name == "sttestpretestfn005"
    error_message = "Function Storage Account output should include the correct name"
  }

  # Verify other services are null
  assert {
    condition     = output.event_hub == null
    error_message = "Event Hub output should be null when should_create_event_hubs is false"
  }

  assert {
    condition     = output.event_grid == null
    error_message = "Event Grid output should be null when should_create_event_grid is false"
  }
}

# Test outputs when Azure Functions and Event Hub are both created
run "verify_outputs_functions_and_event_hub" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "006"

    should_create_azure_functions = true
    should_create_event_hubs      = true
    should_create_event_grid      = false
  }

  # Verify both Azure Functions and Event Hub outputs are set
  assert {
    condition     = output.app_service_plan != null
    error_message = "App Service Plan output should be defined when should_create_azure_functions is true"
  }

  assert {
    condition     = output.function_app != null
    error_message = "Function App output should be defined when should_create_azure_functions is true"
  }

  assert {
    condition     = output.event_hub != null
    error_message = "Event Hub output should be defined when should_create_event_hubs is true"
  }

  # Verify Event Grid is null
  assert {
    condition     = output.event_grid == null
    error_message = "Event Grid output should be null when should_create_event_grid is false"
  }
}

# Test outputs when Azure Functions is disabled
run "verify_outputs_no_azure_functions" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "007"

    should_create_azure_functions = false
    should_create_event_hubs      = true
    should_create_event_grid      = false
  }

  # Verify Azure Functions outputs are null
  assert {
    condition     = output.app_service_plan == null
    error_message = "App Service Plan output should be null when should_create_azure_functions is false"
  }

  assert {
    condition     = output.function_app == null
    error_message = "Function App output should be null when should_create_azure_functions is false"
  }

  assert {
    condition     = output.function_storage_account == null
    error_message = "Function Storage Account output should be null when should_create_azure_functions is false"
  }

  # Verify Event Hub is still set
  assert {
    condition     = output.event_hub != null
    error_message = "Event Hub output should be defined when should_create_event_hubs is true"
  }
}
