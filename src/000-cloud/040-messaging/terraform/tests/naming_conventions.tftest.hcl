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
run "verify_event_hub_naming" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_event_hubs = true
    should_create_event_grid = false
  }

  # Verify the Event Hub module is created
  assert {
    condition     = length(module.event_hubs) == 1
    error_message = "The Event Hub module should be created"
  }

  # Check that an output is generated (verifying the module executed)
  assert {
    condition     = module.event_hubs[0].event_hub != null
    error_message = "Event Hub should be created with the expected configuration"
  }

  # Verify the Event Hub namespace name follows the correct pattern
  assert {
    condition     = module.event_hubs[0].event_hub.namespace_name == "evhns-testpre-aio-test-001"
    error_message = "Event Hub namespace should follow the naming pattern 'evhns-{resource_prefix}-aio-{environment}-{instance}'"
  }

  # Verify the Event Hub name follows the correct pattern
  assert {
    condition     = module.event_hubs[0].event_hub.event_hub_name == "evh-testpre-aio-test-001"
    error_message = "Event Hub should follow the naming pattern 'evh-{resource_prefix}-aio-{environment}-{instance}'"
  }
}

# Test Event Grid naming conventions
run "verify_event_grid_naming" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_event_hubs = false
    should_create_event_grid = true
  }

  # Verify the Event Grid module is created
  assert {
    condition     = length(module.event_grid) == 1
    error_message = "The Event Grid module should be created"
  }

  # Check that the endpoint follows the correct pattern
  assert {
    condition     = can(regex("evgns-testpre-test-aio-002.*", module.event_grid[0].event_grid.endpoint))
    error_message = "Event Grid endpoint should contain the namespace name matching pattern 'evgns-{resource_prefix}-{environment}-aio-{instance}'"
  }
}
