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
    resource_prefix              = run.setup_tests.resource_prefix
    environment                  = "dev"
    instance                     = "001"
    resource_group_name          = null
    connected_cluster_name       = null
    azure_monitor_workspace_name = null
    log_analytics_workspace_name = null
    grafana_name                 = null
  }
}

run "create_non_default_configuration" {

  command = plan

  variables {
    resource_prefix              = run.setup_tests.resource_prefix
    environment                  = "dev"
    instance                     = "001"
    resource_group_name          = "rg-test"
    connected_cluster_name       = "arc-test"
    azure_monitor_workspace_name = "azmon-test"
    log_analytics_workspace_name = "log-test"
    grafana_name                 = "amg-test"
  }
}

