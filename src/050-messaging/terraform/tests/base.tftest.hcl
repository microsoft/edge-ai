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
    resource_prefix            = run.setup_tests.resource_prefix
    environment                = "dev"
    instance                   = "001"
    resource_group_name        = null
    custom_locations_name      = null
    connected_cluster_name     = null
    iot_ops_k8s_extension_name = "iot-ops"
    iot_ops_instance_name      = null
    asset_name                 = "oven"
  }
}

run "create_non_default_configuration" {

  command = plan

  variables {
    resource_prefix            = run.setup_tests.resource_prefix
    environment                = "dev"
    instance                   = "002"
    resource_group_name        = "test_rg"
    custom_locations_name      = "test_cl"
    connected_cluster_name     = "test_arc"
    iot_ops_k8s_extension_name = "aio"
    iot_ops_instance_name      = null
    asset_name                 = "oven"
  }
}

