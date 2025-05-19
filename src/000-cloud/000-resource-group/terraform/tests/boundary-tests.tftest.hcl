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

# Test 1: Valid resource_prefix with hyphen
run "valid_resource_prefix_with_hyphen" {
  command = plan

  variables {
    resource_prefix = "edge-ai"
    environment     = "dev"
    location        = "eastus2"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "rg-edge-ai-dev-001"
    error_message = "Resource group name should be created correctly with hyphenated resource_prefix"
  }
}

# Test 2: Resource prefix with all allowed characters
run "valid_resource_prefix_with_all_allowed_chars" {
  command = plan

  variables {
    resource_prefix = "a1-b2-c3"
    environment     = "test"
    location        = "westus2"
    instance        = "002"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "rg-a1-b2-c3-test-002"
    error_message = "Resource group name should be created correctly with alphanumeric and hyphen resource_prefix"
  }
}

# Test 3: Resource prefix with uppercase (should be transformed correctly in result)
run "valid_resource_prefix_with_uppercase" {
  command = plan

  variables {
    resource_prefix = "EdgeAI"
    environment     = "prod"
    location        = "centralus"
    instance        = "003"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "rg-EdgeAI-prod-003"
    error_message = "Resource group name should be created correctly with uppercase in resource_prefix"
  }
}

# Test 4: Valid min length instance
run "valid_min_length_instance" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "eastus2"
    instance        = "1"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "rg-${run.setup_tests.resource_prefix}-dev-1"
    error_message = "Resource group name should be created correctly with minimal length instance"
  }
}

# Test 5: Valid locations in different formats
run "valid_location_different_formats" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    # Location can be in various formats (we use lowercase here)
    location = "eastus"
    instance = "005"
  }

  assert {
    condition     = azurerm_resource_group.new.location == "eastus"
    error_message = "Resource group location should match the provided location exactly"
  }
}
