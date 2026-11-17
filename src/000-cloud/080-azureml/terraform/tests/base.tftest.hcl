mock_provider "azapi" {}

mock_provider "azurerm" {
  override_data {
    target = data.azurerm_client_config.current
    values = {
      object_id = "55555555-5555-5555-5555-555555555555"
      tenant_id = "11111111-1111-1111-1111-111111111111"
    }
  }
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: Default configuration creates the workspace, a compute subnet and a compute cluster
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    instance             = "001"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network
  }

  assert {
    condition     = output.workspace_name == "mlw-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Workspace name does not match expected pattern"
  }

  assert {
    condition     = output.azureml_workspace.location == var.location && output.azureml_workspace.resource_group_name == var.resource_group.name
    error_message = "Workspace should be created in the provided location and resource group"
  }

  assert {
    condition     = length(module.network) == 1
    error_message = "A compute subnet should be created by default"
  }

  assert {
    condition     = module.network[0].snet_azureml.name == "subnet-${var.resource_prefix}-azureml-${var.environment}-${var.instance}"
    error_message = "Compute subnet name does not match expected pattern"
  }

  assert {
    condition     = output.compute_cluster_name == "cluster-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Compute cluster name does not match expected pattern"
  }

  assert {
    condition     = output.registry == null
    error_message = "No registry should be deployed by default"
  }

  assert {
    condition     = output.workspace_private_endpoint == null && length(output.workspace_private_dns_zones) == 0
    error_message = "No private endpoint or private DNS zones should be created by default"
  }

  assert {
    condition     = output.azureml_extension == null && output.kubernetes_compute == null
    error_message = "No AKS integration should be created by default"
  }

  assert {
    condition     = output.ml_workload_identity == null
    error_message = "No workload identity should be set by default"
  }
}

# Test 2: Provided names are used and an existing subnet replaces the component subnet
run "create_with_custom_names_and_existing_subnet" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    instance             = "001"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    workspace_name                     = "mlw-custom"
    compute_cluster_name               = "cluster-custom"
    should_create_compute_cluster_snet = false
    compute_cluster_subnet             = run.setup_tests.compute_cluster_subnet
  }

  assert {
    condition     = output.workspace_name == "mlw-custom"
    error_message = "Workspace should use the provided name"
  }

  assert {
    condition     = output.compute_cluster_name == "cluster-custom"
    error_message = "Compute cluster should use the provided name"
  }

  assert {
    condition     = length(module.network) == 0
    error_message = "No compute subnet should be created when should_create_compute_cluster_snet is false"
  }

  assert {
    condition     = length(module.compute_cluster) == 1
    error_message = "Compute cluster should still be created on the existing subnet"
  }
}

# Test 3: Disabling the compute cluster skips the cluster and its subnet
run "create_without_compute_cluster" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    instance             = "001"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_create_compute_cluster = false
  }

  assert {
    condition     = length(module.compute_cluster) == 0 && length(module.network) == 0
    error_message = "Neither the compute cluster nor its subnet should be created when should_create_compute_cluster is false"
  }

  assert {
    condition     = output.compute_cluster_name == null && output.compute_cluster_id == null
    error_message = "Compute cluster outputs should be null when no cluster is created"
  }
}

# Test 4: Private endpoint creates the workspace endpoint and its DNS zones
run "create_with_private_endpoint" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    instance             = "001"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_enable_private_endpoint = true
    private_endpoint_subnet_id     = run.setup_tests.private_endpoint_subnet_id
  }

  assert {
    condition     = output.workspace_private_endpoint.name == "pe-mlw-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Workspace private endpoint name does not match expected pattern"
  }

  assert {
    condition     = length(output.workspace_private_dns_zones) == 2
    error_message = "Two private DNS zones should be created for the workspace private endpoint"
  }

  assert {
    condition     = output.workspace_private_dns_zones["privatelink.api.azureml.ms"].name == "privatelink.api.azureml.ms" && output.workspace_private_dns_zones["privatelink.notebooks.azure.net"].name == "privatelink.notebooks.azure.net"
    error_message = "Private DNS zones should cover the Azure ML API and notebooks endpoints"
  }


}

# Test 5: AKS integration installs the extension and derives a valid compute target name
run "integrate_aks_cluster" {
  command = plan

  # The extension output wraps the resource in try(), so an unknown id hides it at plan,
  # and the compute target reads the extension identity, which the mock leaves empty.
  override_resource {
    target          = module.inference_cluster_integration[0].azurerm_kubernetes_cluster_extension.azureml
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test/providers/Microsoft.KubernetesConfiguration/extensions/azureml"
      aks_assigned_identity = [
        {
          principal_id = "44444444-4444-4444-4444-444444444444"
          tenant_id    = "11111111-1111-1111-1111-111111111111"
          type         = "SystemAssigned"
        }
      ]
    }
  }

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "staging-west"
    instance             = "001"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_create_compute_cluster = false
    should_integrate_aks_cluster  = true
    kubernetes                    = run.setup_tests.kubernetes
  }

  assert {
    condition     = length(module.inference_cluster_integration) == 1
    error_message = "AKS integration should be created when should_integrate_aks_cluster is true"
  }

  assert {
    condition     = output.azureml_extension.name == "azureml-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Extension name does not match expected pattern"
  }

  assert {
    condition     = module.inference_cluster_integration[0].compute_target_name == "ml${var.resource_prefix}stagingwe"
    error_message = "Compute target name should drop hyphens and be truncated to 16 characters"
  }
}

# Test 6: Single-variable validations reject unsupported values
run "reject_invalid_inputs" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    compute_cluster_max_nodes     = 0
    compute_cluster_vm_priority   = "Spot"
    inference_router_service_type = "ExternalName"
    aks_cluster_purpose           = "Production"
  }

  expect_failures = [
    var.compute_cluster_max_nodes,
    var.compute_cluster_vm_priority,
    var.inference_router_service_type,
    var.aks_cluster_purpose,
  ]
}

# Test 7: Resource prefix must be short lowercase alphanumerics
run "reject_invalid_resource_prefix" {
  command = plan

  variables {
    resource_prefix      = "Invalid-Prefix"
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network
  }

  expect_failures = [
    var.resource_prefix,
  ]
}

# Test 8: NAT gateway association requires a NAT gateway object
run "reject_nat_gateway_enabled_without_nat_gateway" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_enable_nat_gateway = true
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}

# Test 9: A plan targeting only the network module still enforces the NAT gateway rule
run "reject_nat_gateway_enabled_without_nat_gateway_targeted" {
  command = plan

  plan_options {
    target = [module.network]
  }

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_enable_nat_gateway = true
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}

# Test 10: A plan targeting only the network module still enforces the NSG rule
run "reject_nsg_association_without_nsg_targeted" {
  command = plan

  plan_options {
    target = [module.network]
  }

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_associate_network_security_group = true
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}

# Test 11: Workload identity role assignment requires a workload identity object
run "reject_workload_identity_roles_without_identity" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_assign_ml_workload_identity_roles = true
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}

# Test 12: A plan targeting only the workspace module still enforces the workload identity rule
run "reject_workload_identity_roles_without_identity_targeted" {
  command = plan

  plan_options {
    target = [module.workspace]
  }

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    should_assign_ml_workload_identity_roles = true
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}

# Test 13: Minimum node count cannot exceed the maximum node count
run "reject_min_nodes_above_max_nodes" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "test"
    location             = run.setup_tests.location
    resource_group       = run.setup_tests.resource_group
    application_insights = run.setup_tests.application_insights
    key_vault            = run.setup_tests.key_vault
    storage_account      = run.setup_tests.storage_account
    acr                  = run.setup_tests.acr
    virtual_network      = run.setup_tests.virtual_network

    compute_cluster_min_nodes = 3
    compute_cluster_max_nodes = 2
  }

  expect_failures = [
    data.azurerm_client_config.current,
  ]
}
