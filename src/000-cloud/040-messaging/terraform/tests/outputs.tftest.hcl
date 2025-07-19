mock_provider "azurerm" {
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

    should_create_eventhub  = true
    should_create_eventgrid = true
  }

  # Verify the Event Grid outputs are correctly set
  assert {
    condition     = output.eventgrid != null
    error_message = "Event Grid output should be defined when should_create_eventgrid is true"
  }

  assert {
    condition     = output.eventgrid.topic_name == "default"
    error_message = "Event Grid output should include the default topic_name"
  }

  assert {
    condition     = output.eventgrid.endpoint == "evgns-testpre-test-aio-001.${var.resource_group.location}-1.ts.eventgrid.azure.net:8883"
    error_message = "Event Grid endpoint output should have the correct format"
  }
}

# Test outputs when only Event Hub is created
run "verify_eventhub_configuration" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_eventhub  = true
    should_create_eventgrid = false
  }

  # Verify the Event Grid output is null
  assert {
    condition     = output.eventgrid == null
    error_message = "Event Grid output should be null when should_create_eventgrid is false"
  }
}

# Test outputs when only Event Grid is created
run "verify_outputs_only_eventgrid" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    should_create_eventhub  = false
    should_create_eventgrid = true
  }

  # Verify the Event Hub output is null
  assert {
    condition     = output.eventhub_namespace == null
    error_message = "Event Hub output should be null when should_create_eventhub is false"
  }

  # Verify the Event Grid output is correctly set
  assert {
    condition     = output.eventgrid != null
    error_message = "Event Grid output should be defined when should_create_eventgrid is true"
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

    should_create_eventhub  = false
    should_create_eventgrid = false
  }

  # Verify all outputs are null
  assert {
    condition     = output.eventhub_namespace == null
    error_message = "Event Hub output should be null when should_create_eventhub is false"
  }

  assert {
    condition     = output.eventgrid == null
    error_message = "Event Grid output should be null when should_create_eventgrid is false"
  }
}
