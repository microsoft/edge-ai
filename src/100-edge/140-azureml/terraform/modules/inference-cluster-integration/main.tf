/**
 * # Arc Inference Cluster Integration Module
 *
 * Deploys Azure Machine Learning extension on Arc-enabled Kubernetes cluster
 * and attaches it to Azure ML workspace. This task adds base
 * role assignments (Reader, Kubernetes Extension Contributor, Cluster Admin)
 * dependent on extension deployment completion.
 */

locals {
  extension_name             = coalesce(var.extension_name, "azureml-${var.resource_prefix}-${var.environment}-${var.instance}")
  has_ssl_config             = var.ssl_cert_pem != null && var.ssl_key_pem != null && var.ssl_cname != null
  allow_insecure_connections = !local.has_ssl_config
  arc_compute_target_name    = coalesce(var.compute_target_name, "arck-${var.resource_prefix}-${var.environment}-${var.instance}")

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
    enableTraining             = var.enable_training
    enableInference            = var.enable_inference
    inferenceRouterServiceType = var.inference_router_service_type
    allowInsecureConnections   = tostring(local.allow_insecure_connections)
    inferenceRouterHA          = var.inference_router_ha
    installNvidiaDevicePlugin  = tostring(var.should_install_nvidia_device_plugin)
    installPromOp              = tostring(var.should_install_prom_op)
    installVolcano             = tostring(var.should_install_volcano)
    installDcgmExporter        = tostring(var.should_install_dcgm_exporter)
    clusterPurpose             = tostring(var.cluster_purpose)
    clusterName                = var.cluster_name

    // General Settings
    "servicebus.enabled" = tostring(false)

    // Ignored Gateway Settings (AzureML Extension breaks without setting these...)
    domain       = "ignored125248sjflsiw.cloudapp.azure.com"
    location     = var.location
    cluster_name = "ignored"

    // Azure Arc-enabled Kubernetes specific settings
    "relayserver.enabled" = tostring(true)
  }

  // Final configuration with tolerations merged
  configuration_settings = merge(
    local.base_configuration,
    local.system_toleration_config,
    local.workload_toleration_config
  )

  ml_workload_subjects = var.ml_workload_subjects
}

// OIDC issuer lookup for workload identity federation
data "azapi_resource" "arc_oidc" {
  count = var.ml_workload_identity != null ? 1 : 0

  type        = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"
  resource_id = var.cluster_id

  response_export_values = ["properties.oidcIssuerProfile.issuerUrl"]
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
  issuer              = data.azapi_resource.arc_oidc[0].output.properties.oidcIssuerProfile.issuerUrl
  subject             = each.value
}

resource "azurerm_arc_kubernetes_cluster_extension" "azureml" {
  name           = local.extension_name
  cluster_id     = var.cluster_id
  extension_type = "Microsoft.AzureML.Kubernetes"

  configuration_settings = local.configuration_settings

  configuration_protected_settings = local.has_ssl_config ? {
    sslCname       = tostring(var.ssl_cname)
    sslCertPemFile = tostring(var.ssl_cert_pem)
    sslKeyPemFile  = tostring(var.ssl_key_pem)
  } : {}

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "reader" {
  depends_on                       = [azurerm_arc_kubernetes_cluster_extension.azureml]
  scope                            = var.cluster_id
  role_definition_name             = "Reader"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "extension_contributor" {
  depends_on                       = [azurerm_arc_kubernetes_cluster_extension.azureml]
  scope                            = var.cluster_id
  role_definition_name             = "Kubernetes Extension Contributor"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster_admin" {
  depends_on                       = [azurerm_arc_kubernetes_cluster_extension.azureml]
  scope                            = var.cluster_id
  role_definition_name             = "Azure Kubernetes Service Cluster Admin"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

// Relay discovery after extension deployment (Arc creates relay namespace automatically)
data "azapi_resource_list" "relay_namespaces" {
  depends_on = [azurerm_arc_kubernetes_cluster_extension.azureml]
  type       = "Microsoft.Relay/namespaces@2024-01-01"
  parent_id  = var.cluster_resource_group_id

  response_export_values = {
    items = "value[].{id:id,name:name}"
  }
}

resource "azurerm_role_assignment" "relay_owner" {
  depends_on                       = [data.azapi_resource_list.relay_namespaces]
  scope                            = try(data.azapi_resource_list.relay_namespaces.output.items[0].id, null)
  role_definition_name             = "Azure Relay Owner"
  principal_id                     = var.workspace_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azapi_resource" "kubernetes_compute" {
  depends_on = [
    azurerm_arc_kubernetes_cluster_extension.azureml,
    azurerm_role_assignment.reader,
    azurerm_role_assignment.extension_contributor,
    azurerm_role_assignment.cluster_admin
  ]

  type      = "Microsoft.MachineLearningServices/workspaces/computes@2025-01-01-preview"
  name      = local.arc_compute_target_name
  parent_id = var.machine_learning_workspace_id

  body = {
    location = var.location
    properties = {
      computeType = "Kubernetes"
      resourceId  = var.cluster_id

      description      = var.description
      disableLocalAuth = var.disable_local_auth
      computeLocation  = var.location

      properties = {
        namespace                     = var.kubernetes_namespace
        defaultInstanceType           = var.default_instance_type
        instanceTypes                 = var.instance_types
        extensionInstanceReleaseTrain = var.extension_instance_release_train
        vcName                        = var.vc_name
        extensionPrincipalId          = azurerm_arc_kubernetes_cluster_extension.azureml.identity[0].principal_id

        // To be set by extension on creation
        relayConnectionString      = null
        serviceBusConnectionString = null
      }
    }
  }

  // Move identity to resource level (not in body)
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
  }
}
