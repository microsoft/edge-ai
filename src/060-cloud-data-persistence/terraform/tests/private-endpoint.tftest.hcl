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

# Test private endpoint creation
run "private_endpoint_creation" {
  command = plan

  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    resource_group_name     = run.setup_tests.resource_group_name
    location                = run.setup_tests.location
    environment             = run.setup_tests.environment
    instance                = run.setup_tests.instance
    enable_private_endpoint = true
    subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/testrg/providers/Microsoft.Network/virtualNetworks/testvnet/subnets/testsubnet"
  }

  assert {
    condition     = length(module.storage_account.private_endpoint[*]) > 0
    error_message = "Private endpoint was not created when enabled"
  }

  assert {
    condition     = contains(module.storage_account.private_endpoint[0].private_service_connection[0].subresource_names[*], "blob")
    error_message = "Private endpoint should connect to blob subresource"
  }

  assert {
    condition     = module.storage_account.private_endpoint[0].private_service_connection[0].is_manual_connection == false
    error_message = "Private endpoint should use automatic connection"
  }
}

# Test private endpoint is not created when disabled
run "private_endpoint_disabled" {
  command = plan

  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    resource_group_name     = run.setup_tests.resource_group_name
    location                = run.setup_tests.location
    environment             = run.setup_tests.environment
    instance                = run.setup_tests.instance
    enable_private_endpoint = false
    subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/testrg/providers/Microsoft.Network/virtualNetworks/testvnet/subnets/testsubnet"
  }

  assert {
    condition     = length(module.storage_account.private_endpoint[*]) == 0
    error_message = "Private endpoint should not be created when disabled"
  }
}