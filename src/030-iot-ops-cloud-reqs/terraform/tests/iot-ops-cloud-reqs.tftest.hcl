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
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    aio_resource_group = run.setup_tests.aio_resource_group
  }
}

run "create_non_default_configuration" {
  command = plan
  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    aio_resource_group = run.setup_tests.aio_resource_group
    sse_key_vault      = run.setup_tests.sse_key_vault
  }
}
