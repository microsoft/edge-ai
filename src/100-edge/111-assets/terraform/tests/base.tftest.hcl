mock_provider "azapi" {}

mock_provider "azurerm" {}

mock_provider "azuread" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: CI defaults, no assets or devices are created
run "create_default_configuration" {
  command = plan

  variables {
    location           = run.setup_tests.location
    resource_group     = run.setup_tests.resource_group
    custom_location_id = run.setup_tests.custom_location_id
    adr_namespace      = run.setup_tests.adr_namespace
  }

  assert {
    condition     = length(azapi_resource.asset_endpoint_profile) == 0
    error_message = "Asset endpoint profiles should not be created when should_create_default_asset is false"
  }

  assert {
    condition     = length(azapi_resource.asset) == 0
    error_message = "Assets should not be created when should_create_default_asset is false"
  }

  assert {
    condition     = length(azapi_resource.namespaced_device) == 0
    error_message = "Namespaced devices should not be created when should_create_default_namespaced_asset is false"
  }

  assert {
    condition     = length(azapi_resource.namespaced_asset) == 0
    error_message = "Namespaced assets should not be created when should_create_default_namespaced_asset is false"
  }

  assert {
    condition     = length(module.k8_bridge_role_assignment) == 0
    error_message = "K8 Bridge role assignment should not be created when asset discovery is disabled"
  }

  assert {
    condition     = output.should_enable_opc_asset_discovery == false
    error_message = "OPC asset discovery should be disabled by default"
  }
}

# Test 2: Default legacy and namespaced assets are created
run "create_default_assets" {
  command = plan

  variables {
    location           = run.setup_tests.location
    resource_group     = run.setup_tests.resource_group
    custom_location_id = run.setup_tests.custom_location_id
    adr_namespace      = run.setup_tests.adr_namespace

    should_create_default_asset            = true
    should_create_default_namespaced_asset = true
  }

  assert {
    condition     = keys(azapi_resource.asset_endpoint_profile) == ["opc-ua-connector-0"]
    error_message = "Default asset endpoint profile should be created"
  }

  assert {
    condition     = startswith(azapi_resource.asset_endpoint_profile["opc-ua-connector-0"].type, "Microsoft.DeviceRegistry/assetEndpointProfiles@")
    error_message = "Asset endpoint profile resource type is not correct"
  }

  assert {
    condition     = keys(azapi_resource.asset) == ["oven"]
    error_message = "Default asset should be created"
  }

  assert {
    condition     = startswith(azapi_resource.asset["oven"].type, "Microsoft.DeviceRegistry/assets@")
    error_message = "Asset resource type is not correct"
  }

  assert {
    condition     = azapi_resource.asset["oven"].parent_id == var.resource_group.id
    error_message = "Asset should be created in the resource group"
  }

  assert {
    condition     = keys(azapi_resource.namespaced_device) == ["namespaced-opc-ua-connector"]
    error_message = "Default namespaced device should be created"
  }

  assert {
    condition     = startswith(azapi_resource.namespaced_device["namespaced-opc-ua-connector"].type, "Microsoft.DeviceRegistry/namespaces/devices@")
    error_message = "Namespaced device resource type is not correct"
  }

  assert {
    condition     = keys(azapi_resource.namespaced_asset) == ["namespace-oven"]
    error_message = "Default namespaced asset should be created"
  }

  assert {
    condition     = azapi_resource.namespaced_asset["namespace-oven"].parent_id == var.adr_namespace.id
    error_message = "Namespaced asset should be created in the ADR namespace"
  }

  assert {
    condition     = length(module.k8_bridge_role_assignment) == 0
    error_message = "K8 Bridge role assignment should not be created when asset discovery is disabled"
  }
}

# Test 3: Asset discovery on an endpoint profile creates the K8 Bridge role assignment
run "create_endpoint_profile_with_asset_discovery" {
  command = plan

  variables {
    location                = run.setup_tests.location
    resource_group          = run.setup_tests.resource_group
    custom_location_id      = run.setup_tests.custom_location_id
    adr_namespace           = run.setup_tests.adr_namespace
    k8s_bridge_principal_id = run.setup_tests.k8s_bridge_principal_id

    asset_endpoint_profiles = [
      {
        name                              = "opc-ua-discovery"
        target_address                    = "opc.tcp://opcplc-000000:50000"
        should_enable_opc_asset_discovery = true
      }
    ]
  }

  assert {
    condition     = keys(azapi_resource.asset_endpoint_profile) == ["opc-ua-discovery"]
    error_message = "Custom asset endpoint profile should be created"
  }

  assert {
    condition     = output.should_enable_opc_asset_discovery == true
    error_message = "OPC asset discovery should be enabled when an endpoint profile enables it"
  }

  assert {
    condition     = length(module.k8_bridge_role_assignment) == 1
    error_message = "K8 Bridge role assignment should be created when asset discovery is enabled"
  }

  assert {
    condition     = module.k8_bridge_role_assignment[0].k8s_bridge_principal_id == var.k8s_bridge_principal_id
    error_message = "K8 Bridge role assignment should use the provided principal ID"
  }
}
