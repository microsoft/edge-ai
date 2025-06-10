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

# Apply run block to create a default network
run "create_default_network" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "001"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
  }

  # Subnet assertions
  assert {
    condition     = azurerm_subnet.main.name == "snet-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Subnet name does not match expected pattern"
  }

  # NSG assertions
  assert {
    condition     = azurerm_network_security_group.main.name == "nsg-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Network Security Group name does not match expected pattern"
  }

  # Virtual Network assertions
  assert {
    condition     = azurerm_virtual_network.main.name == "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Virtual Network name does not match expected pattern"
  }
}

# Test VM with user assigned managed identity
run "create_non_default_network" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "001"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
    virtual_network_config = {
      address_space         = "10.1.0.0/16"
      subnet_address_prefix = "10.1.3.0/24"
    }
  }

  # Subnet assertions
  assert {
    condition     = azurerm_subnet.main.name == "snet-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Subnet name does not match expected pattern"
  }

  # NSG assertions
  assert {
    condition     = azurerm_network_security_group.main.name == "nsg-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Network Security Group name does not match expected pattern"
  }

  # Virtual Network assertions
  assert {
    condition     = azurerm_virtual_network.main.name == "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Virtual Network name does not match expected pattern"
  }
}
