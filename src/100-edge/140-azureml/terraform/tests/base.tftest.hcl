# The kubernetes_compute output wraps the whole compute resource in try(), so any
# unknown computed attribute hides the full object at plan. Fix the computed values
# that it depends on during plan.
mock_provider "azapi" {
  override_resource {
    target          = module.inference_cluster_integration.azapi_resource.kubernetes_compute
    override_during = plan
    values = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.MachineLearningServices/workspaces/mlw-test/computes/arck-test"
      output = {}
    }
  }
}

mock_provider "azurerm" {
  override_resource {
    target          = module.inference_cluster_integration.azurerm_arc_kubernetes_cluster_extension.azureml
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Kubernetes/connectedClusters/arck-test/providers/Microsoft.KubernetesConfiguration/extensions/azureml"
      identity = {
        principal_id = "44444444-4444-4444-4444-444444444444"
        tenant_id    = "11111111-1111-1111-1111-111111111111"
      }
    }
  }
}

mock_provider "tls" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: Default configuration attaches the Arc cluster to the workspace as a Kubernetes compute target
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "test"
    instance                        = "001"
    location                        = run.setup_tests.location
    resource_group                  = run.setup_tests.resource_group
    connected_cluster               = run.setup_tests.connected_cluster
    machine_learning_workspace      = run.setup_tests.machine_learning_workspace
    workspace_identity_principal_id = run.setup_tests.workspace_identity_principal_id
  }

  assert {
    condition     = output.extension.name == "azureml-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Extension name does not match expected pattern"
  }

  assert {
    condition     = output.kubernetes_compute.name == "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Compute target name does not match expected pattern"
  }

  assert {
    condition     = output.kubernetes_compute.parent_id == var.machine_learning_workspace.id
    error_message = "Compute target should be created in the provided workspace"
  }

  assert {
    condition     = output.kubernetes_compute.body.location == var.location && output.kubernetes_compute.body.properties.computeLocation == var.location
    error_message = "Compute target should use the provided location"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.computeType == "Kubernetes"
    error_message = "Compute target should be a Kubernetes compute"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.resourceId == var.connected_cluster.id
    error_message = "Compute target should point at the connected cluster"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.description == "Azure ML Arc compute target for ${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Compute target description should default to the Arc compute target description"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.disableLocalAuth == true
    error_message = "Local auth should be disabled by default"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.namespace == "azureml"
    error_message = "Compute target namespace should default to azureml"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.defaultInstanceType == "defaultinstancetype"
    error_message = "Default instance type should default to defaultinstancetype"
  }

  assert {
    condition     = length(output.kubernetes_compute.body.properties.properties.instanceTypes) == 1 && can(output.kubernetes_compute.body.properties.properties.instanceTypes.defaultinstancetype)
    error_message = "Only the default instance type should be defined by default"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.instanceTypes.defaultinstancetype.resources.limits.memory == "8Gi" && output.kubernetes_compute.body.properties.properties.instanceTypes.defaultinstancetype.resources.requests.cpu == "0.1"
    error_message = "Default instance type should use the component's resource requests and limits"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.extensionInstanceReleaseTrain == "Stable"
    error_message = "Extension release train should default to Stable"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.vcName == null
    error_message = "Virtual cluster name should not be set by default"
  }

  assert {
    condition     = output.kubernetes_compute.identity[0].type == "SystemAssigned"
    error_message = "Compute target should use a system-assigned identity by default"
  }
}

# Test 2: Provided names, instance types and compute settings are passed through
run "create_with_custom_compute_settings" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "test"
    instance                        = "001"
    location                        = run.setup_tests.location
    resource_group                  = run.setup_tests.resource_group
    connected_cluster               = run.setup_tests.connected_cluster
    machine_learning_workspace      = run.setup_tests.machine_learning_workspace
    workspace_identity_principal_id = run.setup_tests.workspace_identity_principal_id

    extension_name                                       = "azureml-custom"
    arc_compute_target_name                              = "arc-custom"
    cluster_integration_description                      = "Custom Arc compute"
    cluster_integration_disable_local_auth               = false
    cluster_integration_kubernetes_namespace             = "ml-workloads"
    cluster_integration_default_instance_type            = "gpu"
    cluster_integration_extension_instance_release_train = "Preview"
    cluster_integration_vc_name                          = "vc-edge"
    cluster_integration_workspace_identity_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-workspace"
    cluster_integration_instance_types = {
      gpu = {
        nodeSelector = {
          "nvidia.com/gpu.present" = "true"
        }
        resources = {
          limits = {
            cpu              = "4"
            memory           = "16Gi"
            "nvidia.com/gpu" = "1"
          }
        }
      }
    }
  }

  assert {
    condition     = output.extension.name == "azureml-custom"
    error_message = "Extension should use the provided name"
  }

  assert {
    condition     = output.kubernetes_compute.name == "arc-custom"
    error_message = "Compute target should use the provided name"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.description == "Custom Arc compute"
    error_message = "Compute target should use the provided description"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.disableLocalAuth == false
    error_message = "Local auth setting should be passed through"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.namespace == "ml-workloads"
    error_message = "Compute target should use the provided namespace"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.defaultInstanceType == "gpu"
    error_message = "Compute target should use the provided default instance type"
  }

  assert {
    condition     = length(output.kubernetes_compute.body.properties.properties.instanceTypes) == 1 && can(output.kubernetes_compute.body.properties.properties.instanceTypes.gpu)
    error_message = "Provided instance types should replace the default instance type"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.instanceTypes.gpu.resources.limits["nvidia.com/gpu"] == "1"
    error_message = "Provided instance type resources should be passed through"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.extensionInstanceReleaseTrain == "Preview"
    error_message = "Compute target should use the provided release train"
  }

  assert {
    condition     = output.kubernetes_compute.body.properties.properties.vcName == "vc-edge"
    error_message = "Compute target should use the provided virtual cluster name"
  }

  assert {
    condition     = output.kubernetes_compute.identity[0].type == "UserAssigned" && tolist(output.kubernetes_compute.identity[0].identity_ids) == tolist([var.cluster_integration_workspace_identity_id])
    error_message = "Compute target should use the provided user-assigned identity"
  }
}

# Test 3: Extension settings, tolerations, TLS and workload identity federation in the integration module
run "configure_extension_with_tls_tolerations_and_workload_identity" {
  command = plan

  module {
    source = "./modules/inference-cluster-integration"
  }

  override_data {
    target = data.azapi_resource.arc_oidc[0]
    values = {
      output = {
        properties = {
          oidcIssuerProfile = {
            issuerUrl = "https://oidc.test/issuer"
          }
        }
      }
    }
  }

  variables {
    extension_name                      = null
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    instance                            = "001"
    location                            = run.setup_tests.location
    cluster_id                          = run.setup_tests.connected_cluster.id
    cluster_name                        = run.setup_tests.connected_cluster.name
    cluster_resource_group_id           = run.setup_tests.resource_group.id
    machine_learning_workspace_id       = run.setup_tests.machine_learning_workspace.id
    workspace_identity_principal_id     = run.setup_tests.workspace_identity_principal_id
    enable_training                     = true
    enable_inference                    = false
    inference_router_ha                 = false
    inference_router_service_type       = "LoadBalancer"
    should_install_dcgm_exporter        = true
    should_install_nvidia_device_plugin = true
    should_install_prom_op              = false
    should_install_volcano              = false
    cluster_purpose                     = "FastProd"
    ssl_cname                           = "ml.edge.test"
    ssl_cert_pem                        = "test-cert"
    ssl_key_pem                         = "test-key"
    compute_target_name                 = null
    ml_workload_identity                = run.setup_tests.ml_workload_identity
    ml_workload_subjects = [
      "system:serviceaccount:azureml:default",
      "system:serviceaccount:azureml:training",
    ]
    system_tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]
    workload_tolerations = [
      {
        key      = "nvidia.com/gpu"
        operator = "Equal"
        value    = "present"
        effect   = "NoSchedule"
      }
    ]
    default_instance_type            = "defaultinstancetype"
    extension_instance_release_train = "Stable"
    instance_types                   = {}
    kubernetes_namespace             = "azureml"
    workspace_identity_id            = null
    vc_name                          = null
    description                      = "Arc compute"
    disable_local_auth               = true
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.extension_type == "Microsoft.AzureML.Kubernetes"
    error_message = "Extension should install the AzureML Kubernetes extension type"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.cluster_id == var.cluster_id
    error_message = "Extension should be installed on the provided cluster"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["enableTraining"] == "true" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["enableInference"] == "false"
    error_message = "Training and inference flags should be passed through as strings"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["inferenceRouterServiceType"] == "LoadBalancer" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["inferenceRouterHA"] == "false"
    error_message = "Inference router settings should be passed through"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["installDcgmExporter"] == "true" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["installNvidiaDevicePlugin"] == "true" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["installPromOp"] == "false" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["installVolcano"] == "false"
    error_message = "Add-on install flags should be passed through as strings"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["clusterPurpose"] == "FastProd" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["clusterName"] == var.cluster_name
    error_message = "Cluster purpose and name should be passed through"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["relayserver.enabled"] == "true" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["servicebus.enabled"] == "false"
    error_message = "Arc clusters should enable the relay server and disable Service Bus"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["allowInsecureConnections"] == "false"
    error_message = "Insecure connections should be disabled when the TLS CNAME, certificate and key are all set"
  }

  assert {
    condition     = nonsensitive(azurerm_arc_kubernetes_cluster_extension.azureml.configuration_protected_settings["sslCname"]) == "ml.edge.test" && nonsensitive(azurerm_arc_kubernetes_cluster_extension.azureml.configuration_protected_settings["sslCertPemFile"]) == "test-cert" && nonsensitive(azurerm_arc_kubernetes_cluster_extension.azureml.configuration_protected_settings["sslKeyPemFile"]) == "test-key"
    error_message = "TLS settings should be passed as protected settings"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["toleration[0].key"] == "CriticalAddonsOnly" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["toleration[0].operator"] == "Exists" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["toleration[0].effect"] == "NoSchedule"
    error_message = "System tolerations should be indexed under toleration"
  }

  assert {
    condition     = !contains(keys(azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings), "toleration[0].value")
    error_message = "Unset toleration fields should be left out of the configuration"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["workLoadToleration[0].key"] == "nvidia.com/gpu" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["workLoadToleration[0].operator"] == "Equal" && azurerm_arc_kubernetes_cluster_extension.azureml.configuration_settings["workLoadToleration[0].value"] == "present"
    error_message = "Workload tolerations should be indexed under workLoadToleration"
  }

  assert {
    condition     = length(azurerm_federated_identity_credential.ml_workload) == 2
    error_message = "One federated identity credential should be created per workload subject"
  }

  assert {
    condition     = azurerm_federated_identity_credential.ml_workload["system:serviceaccount:azureml:training"].name == "aml-azureml-training-fic"
    error_message = "Federated identity credential name should be derived from the service account subject"
  }

  assert {
    condition     = azurerm_federated_identity_credential.ml_workload["system:serviceaccount:azureml:training"].issuer == "https://oidc.test/issuer"
    error_message = "Federated identity credential should use the connected cluster OIDC issuer"
  }

  assert {
    condition     = azurerm_federated_identity_credential.ml_workload["system:serviceaccount:azureml:default"].user_assigned_identity_id == var.ml_workload_identity.id
    error_message = "Federated identity credential should be created on the workload identity"
  }

}

# Test 4: Invalid inference router service type is rejected
run "reject_invalid_inference_router_service_type" {
  command = plan

  variables {
    resource_prefix                 = run.setup_tests.resource_prefix
    environment                     = "test"
    location                        = run.setup_tests.location
    resource_group                  = run.setup_tests.resource_group
    connected_cluster               = run.setup_tests.connected_cluster
    machine_learning_workspace      = run.setup_tests.machine_learning_workspace
    workspace_identity_principal_id = run.setup_tests.workspace_identity_principal_id
    inference_router_service_type   = "ExternalName"
  }

  expect_failures = [
    var.inference_router_service_type,
  ]
}
