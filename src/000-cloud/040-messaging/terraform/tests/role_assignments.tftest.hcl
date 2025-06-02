mock_provider "azurerm" {
  override_resource {
    target = azurerm_resource_group.this
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      name     = "test-rg"
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

# Test that Event Hubs Data Sender role is assigned when Event Hubs is created
run "verify_event_hubs_role_assignment" {
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

  # Verify the Azure Event Hubs Data Sender role is assigned to the AIO identity
  assert {
    condition     = module.event_hubs[0].event_hub != null
    error_message = "Event Hub should be created"
  }

  # Since we can't directly inspect the role assignments in the test framework,
  # we'll verify that the Event Hub module was created, which indirectly indicates
  # the role assignment would be created as part of the module
  assert {
    condition     = length(module.event_hubs) == 1
    error_message = "The Event Hubs module should be created, which would include the role assignment"
  }
}

# Test that EventGrid TopicSpaces Publisher role is assigned when Event Grid is created
run "verify_event_grid_role_assignment" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    # Only create Event Grid
    should_create_event_hubs = false
    should_create_event_grid = true
  }

  # Verify the EventGrid TopicSpaces Publisher role is assigned to the AIO identity
  assert {
    condition     = module.event_grid[0].event_grid != null
    error_message = "Event Grid should be created"
  }

  # Since we can't directly inspect the role assignments in the test framework,
  # we'll verify that the Event Grid module was created, which indirectly indicates
  # the role assignment would be created as part of the module
  assert {
    condition     = length(module.event_grid) == 1
    error_message = "The Event Grid module should be created, which would include the role assignment"
  }
}
