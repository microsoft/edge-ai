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

# Apply run block to create the cluster
run "create_default_cluster" {
  command = plan
  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "dev"
    aio_resource_group  = run.setup_tests.aio_resource_group
    aio_virtual_machine = run.setup_tests.aio_virtual_machine
  }
}

run "create_non_default_cluster" {
  command = plan
  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "dev"
    instance                        = "test"
    aio_resource_group              = run.setup_tests.aio_resource_group
    aio_virtual_machine             = run.setup_tests.aio_virtual_machine
    vm_username                     = "test"
    custom_locations_oid            = "test"
    enable_arc_auto_upgrade         = false
    arc_onboarding_sp_client_id     = "test"
    arc_onboarding_sp_client_secret = "test"
  }
}
