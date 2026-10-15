mock_provider "azurerm" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: CI defaults, existing delegated subnet, generated password stored in Key Vault
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    instance            = "001"
    location            = run.setup_tests.location
    resource_group      = run.setup_tests.resource_group
    delegated_subnet_id = run.setup_tests.delegated_subnet_id
    virtual_network     = run.setup_tests.virtual_network
    key_vault           = run.setup_tests.key_vault
  }

  assert {
    condition     = length(module.network) == 0
    error_message = "Network module should not be created when should_create_delegated_subnet is false"
  }

  assert {
    condition     = output.postgresql_server.name == "psql-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "PostgreSQL server name does not match expected pattern"
  }

  assert {
    condition     = keys(output.databases) == ["defaultdb"]
    error_message = "Only the default database should be created when databases is null"
  }

  assert {
    condition     = length(random_password.admin_password) == 1
    error_message = "Admin password should be generated when should_generate_admin_password is true"
  }

  assert {
    condition     = azurerm_key_vault_secret.admin_username[0].name == "psql-${var.resource_prefix}-${var.environment}-${var.instance}-admin-username"
    error_message = "Admin username secret name does not match expected pattern"
  }

  assert {
    condition     = azurerm_key_vault_secret.admin_username[0].value == "pgadmin"
    error_message = "Admin username secret should store the default admin username"
  }

  assert {
    condition     = azurerm_key_vault_secret.admin_password[0].name == "psql-${var.resource_prefix}-${var.environment}-${var.instance}-admin-password"
    error_message = "Admin password secret name does not match expected pattern"
  }

  assert {
    condition     = azurerm_key_vault_secret.admin_password[0].key_vault_id == var.key_vault.id
    error_message = "Admin password secret should be stored in the provided Key Vault"
  }
}

# Test 2: Delegated subnet created by the component
run "create_with_delegated_subnet" {
  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = "test"
    instance               = "002"
    location               = run.setup_tests.location
    resource_group         = run.setup_tests.resource_group
    virtual_network        = run.setup_tests.virtual_network
    network_security_group = run.setup_tests.network_security_group
    key_vault              = run.setup_tests.key_vault

    should_create_delegated_subnet = true
  }

  assert {
    condition     = length(module.network) == 1
    error_message = "Network module should be created when should_create_delegated_subnet is true"
  }

  assert {
    condition     = module.network[0].postgres_subnet.name == "snet-postgres-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "PostgreSQL subnet name does not match expected pattern"
  }
}

# Test 3: Provided password and DNS zone, custom databases, no Key Vault secrets
run "create_without_key_vault_secrets" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    instance            = "003"
    location            = run.setup_tests.location
    resource_group      = run.setup_tests.resource_group
    delegated_subnet_id = run.setup_tests.delegated_subnet_id
    private_dns_zone = {
      id = "${run.setup_tests.resource_group.id}/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
    }

    admin_password                        = run.setup_tests.admin_password
    should_generate_admin_password        = false
    should_store_credentials_in_key_vault = false

    databases = {
      telemetry = {
        collation = "en_US.utf8"
        charset   = "utf8"
      }
      analytics = {
        collation = "en_US.utf8"
        charset   = "utf8"
      }
    }
  }

  assert {
    condition     = length(random_password.admin_password) == 0
    error_message = "Admin password should not be generated when should_generate_admin_password is false"
  }

  assert {
    condition     = length(azurerm_key_vault_secret.admin_username) == 0 && length(azurerm_key_vault_secret.admin_password) == 0
    error_message = "Key Vault secrets should not be created when should_store_credentials_in_key_vault is false"
  }

  assert {
    condition     = output.admin_username_secret == null && output.admin_password_secret == null
    error_message = "Key Vault secret outputs should be null when should_store_credentials_in_key_vault is false"
  }

  assert {
    condition     = keys(output.databases) == ["analytics", "telemetry"]
    error_message = "One database should be planned for each databases entry"
  }

  assert {
    condition     = output.private_dns_zone_id == var.private_dns_zone.id
    error_message = "Provided private DNS zone should be used"
  }
}
