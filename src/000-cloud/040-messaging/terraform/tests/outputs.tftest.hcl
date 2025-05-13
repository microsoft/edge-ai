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
