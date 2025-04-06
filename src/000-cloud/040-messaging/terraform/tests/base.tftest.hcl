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

    # Defaults will be used
    should_create_event_hubs = true
    should_create_event_grid = true
  }

  assert {
    condition     = module.event_hubs[0].event_hub != null
    error_message = "Event Hub should be created with default configuration"
  }

  assert {
    condition     = module.event_grid[0].event_grid != null
    error_message = "Event Grid should be created with default configuration"
  }
}

run "create_only_event_hubs" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    # Only create Event Hubs
    should_create_event_hubs = true
    should_create_event_grid = false
  }

  assert {
    condition     = module.event_hubs[0].event_hub != null
    error_message = "Event Hub should be created"
  }

  assert {
    condition     = length(module.event_grid) == 0
    error_message = "Event Grid should not be created"
  }
}

run "create_only_event_grid" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    # Only create Event Grid
    should_create_event_hubs = false
    should_create_event_grid = true
  }

  assert {
    condition     = module.event_grid[0].event_grid != null
    error_message = "Event Grid should be created"
  }

  assert {
    condition     = length(module.event_hubs) == 0
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

    # Create neither messaging system
    should_create_event_hubs = false
    should_create_event_grid = false
  }

  assert {
    condition     = length(module.event_hubs) == 0
    error_message = "Event Hub should not be created"
  }

  assert {
    condition     = length(module.event_grid) == 0
    error_message = "Event Grid should not be created"
  }
}
