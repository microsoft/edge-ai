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

# Test the default cluster configuration
run "create_default_cluster" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine  = run.setup_tests.aio_virtual_machine
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = false
    arc_onboarding_sp               = run.setup_tests.mock_sp
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
  }

  # Assertions for the default configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-001"
    error_message = "Arc resource name does not follow naming convention"
  }

  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 0
    error_message = "Role assignment should not be created when should_assign_roles is false"
  }
}

# Test the default cluster configuration with SP authentication
run "create_default_cluster_with_sp" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine  = run.setup_tests.aio_virtual_machine
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_sp               = run.setup_tests.mock_sp
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
  }

  # Assertions for the default configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-001"
    error_message = "Arc resource name does not follow naming convention"
  }

  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 1
    error_message = "Connected machine onboarding role assignment was not created"
  }

  assert {
    condition     = azurerm_role_assignment.connected_machine_onboarding[0].principal_id == var.arc_onboarding_sp.object_id
    error_message = "Role assignment principal_id does not match the service principal object_id"
  }

  assert {
    condition     = azurerm_role_assignment.connected_machine_onboarding[0].role_definition_name == "Kubernetes Cluster - Azure Arc Onboarding"
    error_message = "Role assignment definition name is incorrect"
  }
}

# Test the default cluster configuration with Managed Identity authentication
run "create_default_cluster_with_identity" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine  = run.setup_tests.aio_virtual_machine
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_identity         = run.setup_tests.mock_identity
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
  }

  # Assertions for the default configuration with managed identity
  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 1
    error_message = "Connected machine onboarding role assignment was not created"
  }

  assert {
    condition     = azurerm_role_assignment.connected_machine_onboarding[0].principal_id == var.arc_onboarding_identity.principal_id
    error_message = "Role assignment principal_id does not match the managed identity principal_id"
  }
}

# Test non-default cluster configuration with custom parameters
run "create_non_default_cluster" {
  command = plan

  variables {
    resource_prefix                      = run.setup_tests.resource_prefix
    environment                          = "dev"
    instance                             = "test"
    resource_group                       = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine       = run.setup_tests.aio_virtual_machine
    cluster_node_virtual_machines        = run.setup_tests.aio_node_virtual_machines
    cluster_server_host_machine_username = "testuser"
    custom_locations_oid                 = run.setup_tests.mock_custom_locations_oid
    should_enable_arc_auto_upgrade       = false
    arc_onboarding_sp                    = run.setup_tests.mock_sp
    should_get_custom_locations_oid      = false
    should_output_cluster_node_script    = true
    should_output_cluster_server_script  = true
    should_generate_cluster_server_token = true
    should_deploy_script_to_vm           = true
    should_assign_roles                  = true
    cluster_admin_oid                    = run.setup_tests.mock_cluster_admin_oid
    key_vault                            = run.setup_tests.key_vault
  }

  # Assertions for custom configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Arc resource name does not follow naming convention with custom instance"
  }

  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 1
    error_message = "Connected machine onboarding role assignment was not created"
  }
}

# Test multi-node cluster configuration with custom IP
run "create_multi_node_cluster" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "prod"
    instance                        = "001"
    resource_group                  = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine  = run.setup_tests.aio_virtual_machine
    cluster_node_virtual_machines   = run.setup_tests.aio_node_virtual_machines
    cluster_server_ip               = "10.0.0.10"
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = false
    arc_onboarding_sp               = run.setup_tests.mock_sp
    key_vault                       = run.setup_tests.key_vault
  }

  # Assertions for multi-node cluster configuration
  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 0
    error_message = "Role assignment should not be created when should_assign_roles is false"
  }

  assert {
    condition     = length(data.azapi_resource.arc_connected_cluster) == 1
    error_message = "Data source for Arc connected cluster should be created when should_deploy_script_to_vm is true"
  }
}

# Test handling of optional parameters
run "test_optional_parameters" {
  command = plan

  variables {
    resource_prefix                       = run.setup_tests.resource_prefix
    environment                           = "test"
    resource_group                        = run.setup_tests.aio_resource_group
    cluster_server_virtual_machine        = run.setup_tests.aio_virtual_machine
    should_get_custom_locations_oid       = false
    should_deploy_script_to_vm            = false
    should_assign_roles                   = false
    arc_onboarding_sp                     = run.setup_tests.mock_sp
    custom_locations_oid                  = run.setup_tests.mock_custom_locations_oid
    should_skip_az_cli_login              = true
    should_skip_installing_az_cli         = true
    should_add_current_user_cluster_admin = false
    key_vault                             = run.setup_tests.key_vault
  }

  # Assertions for optional parameters
  assert {
    condition     = length(data.azapi_resource.arc_connected_cluster) == 0
    error_message = "Data source for Arc connected cluster should not be created when should_deploy_script_to_vm is false"
  }

  assert {
    condition     = local.current_user_oid == null
    error_message = "current_user_oid should be null when should_add_current_user_cluster_admin is false"
  }

  assert {
    condition     = length(azurerm_role_assignment.connected_machine_onboarding) == 0
    error_message = "Role assignment should not be created when should_assign_roles is false"
  }
}
