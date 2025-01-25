# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Import the mock provider
mock_provider "azurerm" {
  source = "./tests/mock"
}

# Apply run block to create the cluster
run "create_default_cluster" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
  }
}

run "create_non_default_cluster" {
  command = plan
  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    instance                        = "002"
    resource_group_name             = "test"
    vm_username                     = "test"
    linux_virtual_machine_name      = "machinetest"
    custom_locations_oid            = "test"
    arc_auto_upgrade                = false
    arc_onboarding_sp_client_id     = "test"
    arc_onboarding_sp_client_secret = "test"
  }
}
