/**
 * # AKS Integration Module
 *
 * Deploys Azure Machine Learning extension on AKS cluster and
 * attaches it to Azure ML workspace as compute target for
 * ML training and inference workloads.
 */

// Local variables for resource naming following Azure conventions
locals {
  extension_name = coalesce(var.extension_name, "azureml-${var.resource_prefix}-${var.environment}-${var.instance}")
  // Azure ML compute names must be 2-16 characters, alphanumerics and hyphens only
  // Pattern: ml{resource_prefix_clean}{environment_clean}{instance} truncated to 16 chars
  aks_compute_target_name = coalesce(var.compute_target_name, substr("ml${replace(var.resource_prefix, "-", "")}${replace(var.environment, "-", "")}${var.instance}", 0, 16))

  has_ssl_config             = var.ssl_cert_pem != null && var.ssl_key_pem != null && var.ssl_cname != null
  allow_insecure_connections = !local.has_ssl_config

  // Convert system tolerations to indexed configuration format
  system_toleration_config = merge([
    for i, t in var.system_tolerations : {
      for k, v in {
        key      = try(t.key, null)
        operator = t.operator
        value    = try(t.value, null)
        effect   = try(t.effect, null)
      } : "toleration[${i}].${k}" => v if v != null
    }
  ]...)

  // Convert workload tolerations to indexed configuration format
  workload_toleration_config = merge([
    for i, t in var.workload_tolerations : {
      for k, v in {
        key      = try(t.key, null)
        operator = t.operator
        value    = try(t.value, null)
        effect   = try(t.effect, null)
      } : "workLoadToleration[${i}].${k}" => v if v != null
    }
  ]...)

  // Merge base configuration with toleration settings
  base_configuration = {
    enableTraining             = tostring(var.should_enable_aks_training)
    enableInference            = tostring(var.should_enable_aks_inference)
    inferenceRouterServiceType = var.inference_router_service_type
    allowInsecureConnections   = tostring(local.allow_insecure_connections)
    inferenceRouterHA          = tostring(var.inference_router_ha)
    installNvidiaDevicePlugin  = tostring(var.should_install_nvidia_device_plugin)
    installPromOp              = tostring(var.should_install_prom_op)
    installVolcano             = tostring(var.should_install_volcano)
    installDcgmExporter        = tostring(var.should_install_dcgm_exporter)
    clusterPurpose             = tostring(var.cluster_purpose)
    clusterName                = var.kubernetes_cluster_name

    // General Settings
    "servicebus.enabled" = tostring(false)

    // Ignored Gateway Settings (AzureML Extension breaks without setting these...)
    domain       = "ignored125248sjflsiw.cloudapp.azure.com"
    location     = var.location
    cluster_name = "ignored"


    // AKS specific settings
    "relayserver.enabled" = tostring(false)
  }

  // Volcano scheduler configuration (if ConfigMap name is provided)
  volcano_scheduler_config = var.volcano_scheduler_configmap_name != null ? {
    "volcanoScheduler.schedulerConfigMap" = var.volcano_scheduler_configmap_name
  } : {}

  // Final configuration with tolerations and volcano scheduler config merged
  configuration_settings = merge(
    local.base_configuration,
    local.system_toleration_config,
    local.workload_toleration_config,
    local.volcano_scheduler_config
  )

  ml_workload_subjects = var.ml_workload_subjects
}

// OIDC issuer lookup for workload identity federation
data "azurerm_kubernetes_cluster" "aks" {
  count = var.ml_workload_identity != null ? 1 : 0

  name                = var.kubernetes_cluster_name
  resource_group_name = var.kubernetes_cluster_resource_group_name
}

// Federated identity credentials for ML workload service accounts
resource "azurerm_federated_identity_credential" "ml_workload" {
  for_each = var.ml_workload_identity != null && length(coalesce(local.ml_workload_subjects, [])) > 0 ? {
    for subject in local.ml_workload_subjects : subject => subject
  } : {}

  name                = "aml-${replace(replace(each.value, "system:serviceaccount:", ""), ":", "-")}-fic"
  parent_id           = var.ml_workload_identity.id
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.aks[0].oidc_issuer_url
  subject             = each.value
}

// Deploy Azure Machine Learning extension on AKS cluster
resource "azurerm_kubernetes_cluster_extension" "azureml" {
  name           = local.extension_name
  cluster_id     = var.kubernetes_cluster_id
  extension_type = "Microsoft.AzureML.Kubernetes"

  configuration_settings = local.configuration_settings

  configuration_protected_settings = local.has_ssl_config ? {
    sslCname       = tostring(var.ssl_cname)
    sslCertPemFile = tostring(var.ssl_cert_pem)
    sslKeyPemFile  = tostring(var.ssl_key_pem)
  } : {}
}

resource "azurerm_role_assignment" "reader" {
  depends_on = [azurerm_kubernetes_cluster_extension.azureml]

  scope                            = var.kubernetes_cluster_id
  role_definition_name             = "Reader"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "extension_contributor" {
  depends_on = [azurerm_kubernetes_cluster_extension.azureml]

  scope                            = var.kubernetes_cluster_id
  role_definition_name             = "Kubernetes Extension Contributor"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster_admin" {
  depends_on = [azurerm_kubernetes_cluster_extension.azureml]

  scope                            = var.kubernetes_cluster_id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

// Force replacement when configuration changes to avoid in-place updates that fail through Azure API.
resource "terraform_data" "replace_kubernetes_compute" {
  input = {
    body = {
      location = var.location
      properties = {
        computeType = "Kubernetes"
        resourceId  = var.kubernetes_cluster_id

        description      = var.description
        disableLocalAuth = var.disable_local_auth
        computeLocation  = var.location

        properties = {
          namespace                     = var.kubernetes_namespace
          defaultInstanceType           = var.default_instance_type
          instanceTypes                 = var.instance_types
          extensionInstanceReleaseTrain = var.extension_instance_release_train
          vcName                        = var.vc_name
          extensionPrincipalId          = azurerm_kubernetes_cluster_extension.azureml.aks_assigned_identity[0].principal_id

          relayConnectionString      = null
          serviceBusConnectionString = null
        }
      }
    }
    workspace_identity_id = var.workspace_identity_id
  }
}

resource "azapi_resource" "kubernetes_compute" {
  depends_on = [
    azurerm_kubernetes_cluster_extension.azureml,
    azurerm_role_assignment.reader,
    azurerm_role_assignment.extension_contributor,
    azurerm_role_assignment.cluster_admin
  ]

  type      = "Microsoft.MachineLearningServices/workspaces/computes@2025-01-01-preview"
  name      = local.aks_compute_target_name
  parent_id = var.machine_learning_workspace_id

  body = terraform_data.replace_kubernetes_compute.output.body

  dynamic "identity" {
    for_each = var.workspace_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.workspace_identity_id]
    }
  }

  dynamic "identity" {
    for_each = var.workspace_identity_id == null ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  // Ignore server-computed properties that cannot be set in configuration
  lifecycle {
    ignore_changes = [
      body.properties.properties.relayConnectionString,
      body.properties.properties.serviceBusConnectionString,
    ]

    replace_triggered_by = [
      terraform_data.replace_kubernetes_compute,
    ]
  }
}
