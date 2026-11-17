mock_provider "azurerm" {}

mock_provider "azapi" {}

# Call the setup module to create fabricated resource group and identity values
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Storage account names may only contain lowercase letters and numbers. The resource_prefix
# validation allows hyphens, so they must be removed from the Function App storage account name.
run "function_storage_name_removes_hyphens" {
  command = plan

  variables {
    resource_prefix = "edge-ai"
    environment     = "dev-eu"
    instance        = "001"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity

    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  assert {
    condition     = module.azure_functions[0].storage_account.name == "stedgeaideveufn001"
    error_message = "Storage Account name should drop hyphens from resource_prefix and environment, got '${module.azure_functions[0].storage_account.name}'"
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", module.azure_functions[0].storage_account.name))
    error_message = "Storage Account name must be 3-24 lowercase letters and numbers"
  }
}

# Names without hyphens are unchanged, so existing storage accounts are not replaced.
run "function_storage_name_without_hyphens_is_unchanged" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    instance        = "003"
    resource_group  = run.setup_tests.resource_group
    aio_identity    = run.setup_tests.aio_identity

    should_create_azure_functions = true
    should_create_eventhub        = false
    should_create_eventgrid       = false
  }

  assert {
    condition     = module.azure_functions[0].storage_account.name == "sttestpretestfn003"
    error_message = "Storage Account should follow the naming pattern 'st{resource_prefix}{environment}fn{instance}'"
  }
}
