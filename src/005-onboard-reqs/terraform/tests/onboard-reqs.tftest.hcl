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

run "create_new_resource_group" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
  }

  assert {
    condition     = azurerm_resource_group.new[0].location == "centralus"
    error_message = "'location' variable is not used properly"
  }
}

run "using_existing_resource_group_with_onboarding_identity" {
  command = plan

  # Mock existing resource group to avoid static state query from `data` resources.
  override_data {
    target = data.azurerm_resource_group.existing[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000"
      name = "rg-test"
    }
  }

  variables {
    resource_prefix                = run.setup_tests.resource_prefix
    environment                    = "dev"
    location                       = "centralus"
    should_create_resource_group   = false
    should_create_onboard_identity = true
    onboard_identity_type          = "sp"
  }
}
