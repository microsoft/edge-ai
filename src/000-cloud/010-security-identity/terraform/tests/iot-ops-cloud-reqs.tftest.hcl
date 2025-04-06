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

# Test default configuration (creates key vault and identities)
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    location           = run.setup_tests.location
    aio_resource_group = run.setup_tests.aio_resource_group

    # Default behavior (true)
    should_create_key_vault  = true
    should_create_identities = true
  }

  assert {
    condition     = module.key_vault[0].key_vault != null
    error_message = "Key vault should be created with default configuration"
  }

  assert {
    condition     = module.identity[0].aio_identity != null
    error_message = "AIO identity should be created with default configuration"
  }
}

# Test custom key vault configuration
run "create_custom_key_vault_configuration" {
  command = plan

  variables {
    resource_prefix              = run.setup_tests.resource_prefix
    environment                  = "test"
    location                     = run.setup_tests.location
    aio_resource_group           = run.setup_tests.aio_resource_group
    key_vault_name               = run.setup_tests.key_vault_name
    key_vault_admin_principal_id = run.setup_tests.key_vault_admin_principal_id
    should_create_key_vault      = true
    should_create_identities     = true
  }

  assert {
    condition     = module.key_vault[0].key_vault != null
    error_message = "Key vault should be created with custom configuration"
  }
}

# Test with externally provided key vault (don't create key vault)
run "use_external_key_vault" {
  command = plan

  variables {
    resource_prefix          = run.setup_tests.resource_prefix
    environment              = "test"
    location                 = run.setup_tests.location
    aio_resource_group       = run.setup_tests.aio_resource_group
    should_create_key_vault  = false
    should_create_identities = true
  }

  assert {
    condition     = length(module.key_vault) == 0
    error_message = "Key vault should not be created when should_create_key_vault = false"
  }
}

# Test with no identities created
run "no_identities_created" {
  command = plan

  variables {
    resource_prefix          = run.setup_tests.resource_prefix
    environment              = "test"
    location                 = run.setup_tests.location
    aio_resource_group       = run.setup_tests.aio_resource_group
    should_create_identities = false
    should_create_key_vault  = true
  }

  assert {
    condition     = length(module.identity) == 0
    error_message = "Identity module should not be created when should_create_identities = false"
  }
}
