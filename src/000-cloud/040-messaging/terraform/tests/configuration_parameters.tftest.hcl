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
run "verify_event_hub_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_event_hubs = true
    should_create_event_grid = false
  }

  # Verify the Event Hub has been created
  assert {
    condition     = contains(keys(module.event_hubs[0]), "event_hub")
    error_message = "Event Hub should be created with default configuration"
  }

  # Verify the Event Hub namespace is configured with the default capacity and Standard SKU
  assert {
    condition     = module.event_hubs[0].event_hub.capacity == 1
    error_message = "Event Hub namespace should be configured with default capacity of 1"
  }

  assert {
    condition     = module.event_hubs[0].event_hub.sku == "Standard"
    error_message = "Event Hub namespace should be configured with Standard SKU"
  }

  # Verify the Event Hub is configured with the default partition count and message retention
  assert {
    condition     = module.event_hubs[0].event_hub.partition_count == 1
    error_message = "Event Hub should be configured with default partition count of 1"
  }

  assert {
    condition     = module.event_hubs[0].event_hub.message_retention == 1
    error_message = "Event Hub should be configured with default message retention of 1 day"
  }
}

# Test Event Grid configuration parameters
run "verify_event_grid_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "001"

    should_create_event_hubs = false
    should_create_event_grid = true
  }

  # Verify Event Grid is created
  assert {
    condition     = contains(keys(module.event_grid[0]), "event_grid")
    error_message = "Event Grid should be created with default configuration"
  }

  # Verify Event Grid namespace is configured with the default capacity and Standard SKU
  assert {
    condition     = module.event_grid[0].event_grid.capacity == 1
    error_message = "Event Grid namespace should be configured with default capacity of 1"
  }

  assert {
    condition     = module.event_grid[0].event_grid.sku == "Standard"
    error_message = "Event Grid namespace should be configured with Standard SKU"
  }

  # Verify Event Grid is configured with the default client sessions
  assert {
    condition     = module.event_grid[0].event_grid.max_client_sessions_per_auth == 8
    error_message = "Event Grid namespace should be configured with default maximum_client_sessions_per_authentication_name of 8"
  }

  # Verify Event Grid has the default topic name
  assert {
    condition     = module.event_grid[0].event_grid.topic_name == "default"
    error_message = "Event Grid should have the default topic name 'default'"
  }

  # Verify Event Grid namespace follows the correct naming pattern
  assert {
    condition     = startswith(module.event_grid[0].event_grid.namespace_name, "evgns-")
    error_message = "Event Grid namespace name should start with 'evgns-'"
  }

  # Verify Event Grid topic space follows the correct naming pattern
  assert {
    condition     = startswith(module.event_grid[0].event_grid.topic_space_name, "evgts-")
    error_message = "Event Grid topic space name should start with 'evgts-'"
  }
}

# Test Event Hub with custom configuration parameters
run "verify_custom_event_hub_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "002"

    should_create_event_hubs = true
    should_create_event_grid = false

    # These will override the defaults in the main module
    event_hub_capacity          = 2
    event_hub_message_retention = 3
    event_hub_partition_count   = 4
  }

  # Verify an Event Hub module is created
  assert {
    condition     = length(module.event_hubs) == 1
    error_message = "There should be one Event Hub module created"
  }

  # Verify the custom capacity is passed to the module
  assert {
    condition     = module.event_hubs[0].event_hub.capacity == var.event_hub_capacity
    error_message = "Event Hub capacity should be set to custom value ${var.event_hub_capacity}"
  }

  # Verify the custom message retention is passed to the module
  assert {
    condition     = module.event_hubs[0].event_hub.message_retention == var.event_hub_message_retention
    error_message = "Event Hub message_retention should be set to custom value ${var.event_hub_message_retention}"
  }

  # Verify the custom partition count is passed to the module
  assert {
    condition     = module.event_hubs[0].event_hub.partition_count == var.event_hub_partition_count
    error_message = "Event Hub partition_count should be set to custom value ${var.event_hub_partition_count}"
  }
}

# Test Event Grid with custom configuration parameters
run "verify_custom_event_grid_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity
    instance        = "003"

    should_create_event_hubs = false
    should_create_event_grid = true

    event_grid_capacity            = 2
    event_grid_max_client_sessions = 6
    event_grid_topic_name          = "custom-topic"
  }

  # Verify an Event Grid module is created
  assert {
    condition     = length(module.event_grid) == 1
    error_message = "There should be one Event Grid module created"
  }

  # Verify the custom capacity is passed to the module
  assert {
    condition     = module.event_grid[0].event_grid.capacity == var.event_grid_capacity
    error_message = "Event Grid capacity should be set to custom value ${var.event_grid_capacity}"
  }

  # Verify the custom max client sessions value is passed to the module
  assert {
    condition     = module.event_grid[0].event_grid.max_client_sessions_per_auth == var.event_grid_max_client_sessions
    error_message = "Event Grid max client sessions should be set to custom value ${var.event_grid_max_client_sessions}"
  }

  assert {
    condition     = module.event_grid[0].event_grid.max_client_sessions_per_auth <= 8
    error_message = "Event Grid max client sessions should be set custom value  less than 8"
  }

  # Verify the custom topic name is passed to the module
  assert {
    condition     = module.event_grid[0].event_grid.topic_name == var.event_grid_topic_name
    error_message = "Event Grid topic name should be set to custom value ${var.event_grid_topic_name}"
  }
}
