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
    resource_prefix            = run.setup_tests.resource_prefix
    aio_resource_group         = run.setup_tests.aio_resource_group
    aio_user_assigned_identity = run.setup_tests.aio_user_assigned_identity
    aio_custom_locations       = run.setup_tests.aio_custom_locations
    aio_instance               = run.setup_tests.aio_instance
    aio_dataflow_profile       = run.setup_tests.aio_dataflow_profile
  }
}

run "create_non_default_configuration" {
  command = plan

  variables {
    resource_prefix            = run.setup_tests.resource_prefix
    aio_resource_group         = run.setup_tests.aio_resource_group
    aio_user_assigned_identity = run.setup_tests.aio_user_assigned_identity
    aio_custom_locations       = run.setup_tests.aio_custom_locations
    aio_instance               = run.setup_tests.aio_instance
    aio_dataflow_profile       = run.setup_tests.aio_dataflow_profile
    asset_name                 = "freezer"
  }
}
