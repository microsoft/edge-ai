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

# Test 1: Verify default tags are applied when no custom tags are provided
run "default_tags_only" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "eastus2"
    instance        = "002"
    # No custom tags provided
  }

  assert {
    condition     = length(keys(azurerm_resource_group.new.tags)) == 2
    error_message = "Default tags count should be 2 (Environment and Instance)"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Environment"] == "dev"
    error_message = "Default Environment tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Instance"] == "002"
    error_message = "Default Instance tag is not set correctly"
  }
}

# Test 2: Verify custom tags are merged with default tags
run "merged_custom_and_default_tags" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    location        = "westus2"
    instance        = "003"
    tags = {
      Department  = "Engineering"
      CostCenter  = "12345"
      Application = "EdgeAI"
    }
  }

  assert {
    condition     = length(keys(azurerm_resource_group.new.tags)) == 5
    error_message = "Tags count should be 5 (2 default + 3 custom)"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Environment"] == "test"
    error_message = "Default Environment tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Instance"] == "003"
    error_message = "Default Instance tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Department"] == "Engineering"
    error_message = "Custom Department tag is not applied"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["CostCenter"] == "12345"
    error_message = "Custom CostCenter tag is not applied"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Application"] == "EdgeAI"
    error_message = "Custom Application tag is not applied"
  }
}

# Test 3: Verify custom tags can override default tags
run "override_default_tags" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "prod"
    location        = "centralus"
    instance        = "001"
    tags = {
      # Override default Environment tag
      Environment = "Production"
      # Add other custom tags
      Owner = "DevOps"
    }
  }

  assert {
    condition     = length(keys(azurerm_resource_group.new.tags)) == 3
    error_message = "Tags count should be 3 (2 default with 1 override + 1 custom)"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Environment"] == "Production"
    error_message = "Custom tag should override default Environment tag"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Instance"] == "001"
    error_message = "Default Instance tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Owner"] == "DevOps"
    error_message = "Custom Owner tag is not applied"
  }
}

# Test 4: Verify empty custom tags doesn't affect default tags
run "empty_custom_tags" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "eastus2"
    instance        = "004"
    tags            = {}
  }

  assert {
    condition     = length(keys(azurerm_resource_group.new.tags)) == 2
    error_message = "Default tags count should be 2 when empty custom tags provided"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Environment"] == "dev"
    error_message = "Default Environment tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Instance"] == "004"
    error_message = "Default Instance tag is not set correctly"
  }
}
