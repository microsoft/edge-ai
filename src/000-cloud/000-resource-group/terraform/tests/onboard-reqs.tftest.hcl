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
    condition     = azurerm_resource_group.new[0].location == var.location
    error_message = "'location' variable is not used properly"
  }

  assert {
    condition     = azurerm_resource_group.new[0].name == "rg-${run.setup_tests.resource_prefix}-dev-001"
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
    condition     = azurerm_resource_group.new[0].name == var.resource_group_name
    error_message = "Custom resource group name is not used"
  }

  assert {
    condition     = azurerm_resource_group.new[0].location == var.location
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
    condition     = contains(keys(azurerm_resource_group.new[0].tags), "Application")
    error_message = "Custom tags were not applied"
  }

  assert {
    condition     = azurerm_resource_group.new[0].tags["Environment"] == var.environment
    error_message = "Default Environment tag is not set correctly"
  }

  assert {
    condition     = azurerm_resource_group.new[0].tags["Owner"] == "DevOps"
    error_message = "Custom tags were not merged properly"
  }
}

# This test is commented out because it requires a real Azure resource group to exist
# To properly test the existing resource group functionality:
# 1. Create a resource group in Azure with the name "existing-rg-name"
# 2. Uncomment and run this test
# 3. Delete the resource group when done
# Alternatively, this functionality could be tested with provider mocks in future Terraform versions
#
# run "use_existing_resource_group" {
#   command = plan
#
#   variables {
#     resource_prefix          = run.setup_tests.resource_prefix
#     environment              = "test"
#     location                 = "eastus"
#     instance                 = "004"
#     resource_group_name      = "existing-rg-name"
#     use_existing_resource_group = true
#   }
#
#   # Assert that the resource group isn't created
#   assert {
#     condition     = length(azurerm_resource_group.new) == 0
#     error_message = "Resource group should not be created when use_existing_resource_group is true"
#   }
#
#   # Assert that the output uses data from the existing resource group
#   assert {
#     condition     = output.resource_group.name == var.resource_group_name
#     error_message = "Resource group name output is not set correctly"
#   }
#
#   assert {
#     condition     = output.resource_group.location == var.location
#     error_message = "Resource group location output is not set correctly"
#   }
# }
