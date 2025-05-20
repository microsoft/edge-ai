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

# Test 1: Custom resource group name that's simple
run "custom_resource_group_name_simple" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "dev"
    location            = "eastus2"
    instance            = "001"
    resource_group_name = "my-custom-rg"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "my-custom-rg"
    error_message = "Custom resource group name (simple) was not used"
  }
}

# Test 2: Custom resource group name with special characters
run "custom_resource_group_name_with_special_chars" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    location            = "westus2"
    instance            = "002"
    resource_group_name = "rg_edge-ai_test-002"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg_edge-ai_test-002"
    error_message = "Custom resource group name (with special chars) was not used"
  }
}

# Test 3: Custom resource group name containing parts of the default pattern
run "custom_resource_group_name_with_pattern_parts" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "prod"
    location            = "centralus"
    instance            = "003"
    resource_group_name = "rg-custom-${run.setup_tests.resource_prefix}-prod"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-custom-${run.setup_tests.resource_prefix}-prod"
    error_message = "Custom resource group name (with pattern parts) was not used"
  }
}

# Test 4: Empty resource group name should fall back to default pattern
run "empty_resource_group_name" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "dev"
    location            = "southcentralus"
    instance            = "004"
    resource_group_name = ""
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-dev-004"
    error_message = "Empty resource group name should fall back to default pattern"
  }
}

# Test 5: Null resource group name should fall back to default pattern
run "null_resource_group_name" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    location            = "northcentralus"
    instance            = "005"
    resource_group_name = null
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-test-005"
    error_message = "Null resource group name should fall back to default pattern"
  }
}
