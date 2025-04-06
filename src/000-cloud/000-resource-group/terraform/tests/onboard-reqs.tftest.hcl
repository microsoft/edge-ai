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

run "create_resource_group_with_default_name" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
    instance        = "001"
  }

  assert {
    condition     = azurerm_resource_group.new.location == "centralus"
    error_message = "'location' variable is not used properly"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "rg-${run.setup_tests.resource_prefix}-dev-001"
    error_message = "Resource group name is not constructed correctly"
  }
}

run "create_resource_group_with_custom_name" {
  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "test"
    location            = "eastus"
    instance            = "002"
    resource_group_name = "custom-rg-name"
  }

  assert {
    condition     = azurerm_resource_group.new.name == "custom-rg-name"
    error_message = "Custom resource group name is not used"
  }

  assert {
    condition     = azurerm_resource_group.new.location == "eastus"
    error_message = "Location is not set correctly"
  }
}

run "create_resource_group_with_custom_tags" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "prod"
    location        = "westus"
    instance        = "003"
    tags = {
      Application = "EdgeAI"
      Owner       = "DevOps"
    }
  }

  assert {
    condition     = contains(keys(azurerm_resource_group.new.tags), "Application")
    error_message = "Custom tags were not applied"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Environment"] == "prod"
    error_message = "Default Environment tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new.tags["Owner"] == "DevOps"
    error_message = "Custom tags were not merged properly"
  }
}
