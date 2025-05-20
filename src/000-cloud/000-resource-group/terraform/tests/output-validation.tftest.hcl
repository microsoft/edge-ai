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

# Test 1: Verify all outputs are correctly populated with default naming
run "verify_outputs_with_default_naming" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "eastus2"
    instance        = "001"
  }

  # Verify the resource group name matches the expected pattern
  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-dev-001"
    error_message = "Resource group name doesn't match expected pattern"
  }

  # Verify the resource group location matches the input location
  assert {
    condition     = azurerm_resource_group.new[0].location == "eastus2"
    error_message = "Resource group location doesn't match input location"
  }

  # Note: We don't verify the resource group ID during plan phase as it's not fully known until apply
}

# Test 2: Verify outputs with custom resource group name
run "verify_outputs_with_custom_naming" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    location            = "westus2"
    instance            = "002"
    resource_group_name = "custom-rg-name"
  }

  # Verify the resource group name matches the custom name
  assert {
    condition     = azurerm_resource_group.new[0].name == "custom-rg-name"
    error_message = "Resource group name doesn't match custom name"
  }

  # Verify the resource group location matches the input location
  assert {
    condition     = azurerm_resource_group.new[0].location == "westus2"
    error_message = "Resource group location doesn't match input location"
  }

  # Note: We don't verify the resource group ID during plan phase as it's not fully known until apply
}

# Test 3: Verify outputs with different locations
run "verify_outputs_with_different_location" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "prod"
    location        = "centralus"
    instance        = "003"
  }

  # Verify the resource group location matches the input location
  assert {
    condition     = azurerm_resource_group.new[0].location == "centralus"
    error_message = "Resource group location doesn't reflect the centralus location"
  }
}
