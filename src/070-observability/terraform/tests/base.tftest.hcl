# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name = "test_name"
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      output = {
        identity = {
          principalId = "test_principal_id"
        }
      }
    }
  }
}

run "create_default_configuration" {

  command = plan

  variables {
    resource_prefix     = run.setup_tests.resource_prefix
    environment         = "dev"
    instance            = "001"
    resource_group_name = null
  }
}

run "create_default_configuration_shared_rg" {

  command = plan

  variables {
    resource_prefix            = run.setup_tests.resource_prefix
    environment                = "dev"
    instance                   = "001"
    shared_resource_group_name = "rg-test-shared"
    resource_group_name        = null
  }
}


run "create_non_default_configuration" {

  command = plan

  variables {
    resource_prefix            = run.setup_tests.resource_prefix
    environment                = "dev"
    instance                   = "001"
    resource_group_name        = "rg-test"
    grafana_admin_principal_id = "test_principal_id"
    grafana_major_version      = "10"
    log_retention_in_days      = 45
    daily_quota_in_gb          = 15
  }
}

