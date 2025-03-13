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
    resource_prefix     = run.setup_tests.resource_prefix
    resource_group_name = run.setup_tests.resource_group_name
    location            = run.setup_tests.location
    environment         = run.setup_tests.environment
    instance            = run.setup_tests.instance
  }

  assert {
    condition     = alltrue([module.storage_account.account_tier == var.storage_account_tier])
    error_message = "Storage account configuration does not match expected values"
  }

  assert {
    condition     = module.storage_account.account_tier == var.storage_account_tier
    error_message = "Storage account tier does not match expected value"
  }

  assert {
    condition     = module.storage_account.account_replication_type == var.storage_account_replication
    error_message = "Storage account replication type does not match expected value"
  }
}

# Test with custom parameters
run "create_custom_configuration" {
  command = plan

  variables {
    resource_prefix                      = run.setup_tests.resource_prefix
    resource_group_name                  = run.setup_tests.resource_group_name
    location                             = run.setup_tests.location
    environment                          = run.setup_tests.environment
    instance                             = run.setup_tests.instance
    storage_account_tier                 = "Premium"
    storage_account_kind                 = "BlockBlobStorage"
    storage_account_replication          = "ZRS"
    blob_soft_delete_retention_days      = 14
    container_soft_delete_retention_days = 14
    data_lake_filesystem_name            = "customdatalake"
    container_name                       = "customcontainer"
    enable_private_endpoint              = true
    subnet_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/testrg/providers/Microsoft.Network/virtualNetworks/testvnet/subnets/testsubnet"
  }

  assert {
    condition     = module.storage_account.account_tier == "Premium"
    error_message = "Storage account tier does not match custom value"
  }

  assert {
    condition     = module.storage_account.account_replication_type == "ZRS"
    error_message = "Storage account replication type does not match custom value"
  }

  assert {
    condition     = module.storage_account.account_kind == "BlockBlobStorage"
    error_message = "Storage account kind does not match custom value"
  }

  assert {
    condition     = length(module.storage_account.private_endpoint[*]) > 0
    error_message = "Private endpoint was not created when enabled"
  }
}

run "test_data_lake_creation" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    resource_group_name = run.setup_tests.resource_group_name
    location            = run.setup_tests.location
    environment         = run.setup_tests.environment
    instance            = run.setup_tests.instance
  }

  assert {
    condition     = module.storage_account.is_hns_enabled == true
    error_message = "Hierarchical namespace should be enabled for Data Lake Gen2"
  }

  assert {
    condition     = module.data_lake.data_lake_filesystem_name == var.data_lake_filesystem_name
    error_message = "Data Lake Gen2 filesystem was not planned to be created with correct name"
  }
}