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

# Test data lake storage creation
run "data_lake_creation" {
  command = plan

  variables {
    resource_prefix           = run.setup_tests.resource_prefix
    resource_group_name       = run.setup_tests.resource_group_name
    location                  = run.setup_tests.location
    environment              = run.setup_tests.environment
    instance                 = run.setup_tests.instance
    data_lake_filesystem_name = "testdatalake"
  }

  assert {
    condition     = module.storage_account.is_hns_enabled == true
    error_message = "Hierarchical namespace should be enabled for Data Lake Gen2"
  }

  assert {
    condition     = module.data_lake.data_lake_filesystem_name == "testdatalake"
    error_message = "Data Lake Gen2 filesystem name does not match expected value"
  }
}

# Test role assignments
run "data_lake_permissions" {
  command = plan

  variables {
    resource_prefix                = run.setup_tests.resource_prefix
    resource_group_name            = run.setup_tests.resource_group_name
    location                       = run.setup_tests.location
    environment                   = run.setup_tests.environment
    instance                      = run.setup_tests.instance
    managed_identity_principal_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = length(module.data_lake.role_assignments_owner[*]) > 0
    error_message = "Storage Blob Data Owner role assignment was not created"
  }

  assert {
    condition     = length(module.data_lake.role_assignments_contributor[*]) > 0
    error_message = "Storage Blob Data Contributor role assignment was not created with managed identity"
  }

  assert {
    condition     = module.data_lake.role_assignments_contributor[0].role_definition_name == "Storage Blob Data Contributor"
    error_message = "Role assignment does not have the correct role definition name"
  }
}