mock_provider "azurerm" {}

mock_provider "fabric" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: CI defaults, no Fabric resources are created and the existing workspace is looked up
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "001"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
  }

  assert {
    condition     = length(module.fabric_capacity) == 0
    error_message = "Fabric capacity should not be created when should_create_fabric_capacity is false"
  }

  assert {
    condition     = length(module.fabric_workspace) == 0
    error_message = "Fabric workspace should not be created when should_create_fabric_workspace is false"
  }

  assert {
    condition     = length(module.fabric_lakehouse) == 0
    error_message = "Fabric lakehouse should not be created when should_create_fabric_lakehouse is false"
  }

  assert {
    condition     = length(module.fabric_eventhouse) == 0
    error_message = "Fabric eventhouse should not be created when should_create_fabric_eventhouse is false"
  }

  assert {
    condition     = length(data.fabric_workspace.existing) == 1
    error_message = "Existing Fabric workspace should be looked up when should_create_fabric_workspace is false"
  }

  assert {
    condition     = length(data.fabric_capacity.existing) == 0 && length(data.fabric_capacity.created) == 0
    error_message = "Fabric capacity should not be looked up when neither capacity nor workspace is created"
  }
}

# Test 2: All Fabric resources are created with default names
run "create_all_fabric_resources" {
  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = "test"
    instance               = "001"
    location               = run.setup_tests.location
    resource_group         = run.setup_tests.resource_group
    fabric_capacity_admins = run.setup_tests.fabric_capacity_admins

    should_create_fabric_capacity   = true
    should_create_fabric_workspace  = true
    should_create_fabric_lakehouse  = true
    should_create_fabric_eventhouse = true
  }

  assert {
    condition     = module.fabric_capacity[0].capacity.display_name == "cap${var.resource_prefix}${var.environment}${var.instance}"
    error_message = "Fabric capacity name does not match expected pattern"
  }

  assert {
    condition     = module.fabric_capacity[0].capacity.sku == "F2"
    error_message = "Fabric capacity should default to the F2 SKU"
  }

  assert {
    condition     = module.fabric_workspace[0].workspace.display_name == "ws-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Fabric workspace name does not match expected pattern"
  }

  assert {
    condition     = module.fabric_lakehouse[0].lakehouse_name == "lh_${var.resource_prefix}_${var.environment}_${var.instance}"
    error_message = "Fabric lakehouse name does not match expected pattern"
  }

  assert {
    condition     = module.fabric_eventhouse[0].eventhouse_name == "evh-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Fabric eventhouse name does not match expected pattern"
  }

  assert {
    condition     = length(data.fabric_capacity.created) == 1 && length(data.fabric_capacity.existing) == 0
    error_message = "Created Fabric capacity should be looked up instead of an existing one"
  }

  assert {
    condition     = length(data.fabric_workspace.existing) == 0
    error_message = "Existing Fabric workspace should not be looked up when should_create_fabric_workspace is true"
  }
}

# Test 3: Eventhouse with additional KQL databases
run "create_eventhouse_with_additional_kql_databases" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "002"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group

    should_create_fabric_workspace  = true
    should_create_fabric_eventhouse = true
    additional_kql_databases = {
      telemetry = {
        display_name = "telemetry"
        description  = "Telemetry database"
      }
      alerts = {
        display_name = "alerts"
        description  = "Alerts database"
      }
    }
  }

  assert {
    condition     = length(module.fabric_eventhouse) == 1
    error_message = "Fabric eventhouse should be created when should_create_fabric_eventhouse is true"
  }

  assert {
    condition     = length(module.fabric_eventhouse[0].kql_database_ids) == 2
    error_message = "One KQL database should be planned for each additional_kql_databases entry"
  }

  assert {
    condition     = length(module.fabric_capacity) == 0
    error_message = "Fabric capacity should not be created when should_create_fabric_capacity is false"
  }
}

# Test 4: Creating a capacity without administrators fails validation
run "create_capacity_without_admins" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "003"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group

    should_create_fabric_capacity = true
    fabric_capacity_admins        = []
  }

  expect_failures = [
    var.fabric_capacity_admins,
  ]
}
