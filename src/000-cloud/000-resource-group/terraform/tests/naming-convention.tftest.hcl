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

# Test 1: Test with different environment values
run "naming_with_different_environments" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "eastus2"
    instance        = "001"
    # Testing with different environment values
    environment = "prod"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-prod-001"
    error_message = "Resource group name should follow convention with environment = prod"
  }
}

# Test 2: Test with different instance values
run "naming_with_different_instance" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "eastus2"
    # Testing with different instance values
    instance = "007"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-dev-007"
    error_message = "Resource group name should follow convention with instance = 007"
  }
}

# Test 3: Test with short resource prefix
run "naming_with_short_prefix" {
  command = plan

  variables {
    # Testing with short resource prefix
    resource_prefix = "ai"
    environment     = "test"
    location        = "westus3"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-ai-test-001"
    error_message = "Resource group name should follow convention with short prefix"
  }
}

# Test 4: Test with longer resource prefix (within limits)
run "naming_with_longer_prefix" {
  command = plan

  variables {
    # Testing with a longer resource prefix
    resource_prefix = "aiedgeaccel"
    environment     = "test"
    location        = "westus3"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-aiedgeaccel-test-001"
    error_message = "Resource group name should follow convention with longer prefix"
  }
}

# Test 5: Test with hyphenated resource prefix
run "naming_with_hyphenated_prefix" {
  command = plan

  variables {
    # Testing with a hyphenated resource prefix
    resource_prefix = "ai-edge"
    environment     = "test"
    location        = "westus3"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-ai-edge-test-001"
    error_message = "Resource group name should follow convention with hyphenated prefix"
  }
}
