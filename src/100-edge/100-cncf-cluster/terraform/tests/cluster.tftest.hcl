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
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = false
    arc_onboarding_sp               = run.setup_tests.mock_sp
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
  }

  # Assertions for the default configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-001"
    error_message = "Arc resource name does not follow naming convention"
  }
}

run "create_arc_agents" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = false
    should_deploy_arc_agents        = true
    arc_onboarding_sp               = run.setup_tests.mock_sp
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
    http_proxy                      = run.setup_tests.mock_http_proxy
    private_key_pem                 = run.setup_tests.mock_private_key_pem
  }

  # Assertions for the default configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-001"
    error_message = "Arc resource name does not follow naming convention"
  }
}

# Test the default cluster configuration with SP authentication
run "create_default_cluster_with_sp" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_sp               = run.setup_tests.mock_sp
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
  }

  # Assertions for the default configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-001"
    error_message = "Arc resource name does not follow naming convention"
  }
}

# Test the default cluster configuration with Managed Identity authentication
run "create_default_cluster_with_identity" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_identity         = run.setup_tests.mock_identity
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
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
    cluster_server_machine               = run.setup_tests.cluster_server_machine
  }

  # Assertions for custom configuration
  assert {
    condition     = local.arc_resource_name == "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Arc resource name does not follow naming convention with custom instance"
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
    cluster_server_ip               = "10.0.0.10"
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = false
    arc_onboarding_sp               = run.setup_tests.mock_sp
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
    cluster_node_machine            = [run.setup_tests.cluster_server_machine]
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
    should_get_custom_locations_oid       = false
    should_deploy_script_to_vm            = false
    should_assign_roles                   = false
    arc_onboarding_sp                     = run.setup_tests.mock_sp
    custom_locations_oid                  = run.setup_tests.mock_custom_locations_oid
    should_skip_az_cli_login              = true
    should_skip_installing_az_cli         = true
    should_add_current_user_cluster_admin = false
    key_vault                             = run.setup_tests.key_vault
    cluster_server_machine                = run.setup_tests.cluster_server_machine
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
}

# Test the default cluster configuration with principal ID directly
run "create_default_cluster_with_principal_id" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_principal_ids    = ["00000000-0000-0000-0000-000000000001"]
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
  }
}

# Test invalid configuration with multiple identity approaches
run "test_invalid_multiple_identities" {
  command = plan
  expect_failures = [
    var.arc_onboarding_identity
  ]

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    resource_group                  = run.setup_tests.aio_resource_group
    should_get_custom_locations_oid = false
    should_deploy_script_to_vm      = true
    should_assign_roles             = true
    arc_onboarding_principal_ids    = ["00000000-0000-0000-0000-000000000001"]
    arc_onboarding_identity         = run.setup_tests.mock_identity
    custom_locations_oid            = run.setup_tests.mock_custom_locations_oid
    key_vault                       = run.setup_tests.key_vault
    cluster_server_machine          = run.setup_tests.cluster_server_machine
  }
}

