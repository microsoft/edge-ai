/**
 * # Azure IoT Enablement Module
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.
 *
 */

locals {
  default_storage_class    = var.edge_storage_accelerator.faultToleranceEnabled ? "acstor-arccontainerstorage-storage-pool" : "default,local-path"
  kubernetes_storage_class = var.edge_storage_accelerator.diskStorageClass != "" ? var.edge_storage_accelerator.diskStorageClass : local.default_storage_class
  diskMountPoint           = coalesce(var.edge_storage_accelerator.diskMountPoint, "/mnt")

  container_storage_settings = var.edge_storage_accelerator.faultToleranceEnabled ? {
    "edgeStorageConfiguration.create"               = "true"
    "feature.diskStorageClass"                      = local.kubernetes_storage_class
    "acstorConfiguration.create"                    = "true"
    "acstorConfiguration.properties.diskMountPoint" = local.diskMountPoint
    } : {
    "edgeStorageConfiguration.create" = "true"
    "feature.diskStorageClass"        = local.kubernetes_storage_class
  }
}

data "azapi_resource" "cluster_oidc_issuer" {
  name      = var.connected_cluster_name
  parent_id = var.resource_group.id
  type      = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"

  response_export_values = ["properties.oidcIssuerProfile.issuerUrl"]
}

resource "azurerm_arc_kubernetes_cluster_extension" "secret_store" {
  name           = "azure-secret-store"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.azure.secretstore"
  identity {
    type = "SystemAssigned"
  }
  version       = var.secret_sync_controller.version
  release_train = var.secret_sync_controller.train
  configuration_settings = {
    "rotationPollIntervalInSeconds"             = "120"
    "validatingAdmissionPolicies.applyPolicies" = "false"
  }
  depends_on = [azurerm_arc_kubernetes_cluster_extension.cert_manager]
}

resource "azurerm_arc_kubernetes_cluster_extension" "container_storage" {
  name           = "azure-arc-containerstorage"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.arc.containerstorage"
  identity {
    type = "SystemAssigned"
  }
  version                = var.edge_storage_accelerator.version
  release_train          = var.edge_storage_accelerator.train
  configuration_settings = local.container_storage_settings
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.cert_manager]
}

resource "azurerm_arc_kubernetes_cluster_extension" "cert_manager" {
  count          = var.trust_config_source != "CustomerManagedByoIssuer" ? 1 : 0
  name           = "azure-iot-operations-cert-manager"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.certmanagement"
  identity {
    type = "SystemAssigned"
  }
  version           = var.cert_manager.version
  release_train     = var.cert_manager.train
  release_namespace = "cert-manager"
  configuration_settings = {
    "AgentOperationTimeoutInMinutes" = var.aio_cert_manager_config.agent_operation_timeout_in_minutes
    "global.telemetry.enabled"       = var.aio_cert_manager_config.global_telemetry_enabled
  }
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_sse_aio" {
  count               = var.enable_instance_secret_sync ? 1 : 0
  name                = "aio-sse-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.secret_sync_identity.id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-ssc-sa"
}

resource "azurerm_federated_identity_credential" "federated_identity_cred_aio_instance" {
  name                = "aio-instance-ficred"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azapi_resource.cluster_oidc_issuer.output.properties.oidcIssuerProfile.issuerUrl
  parent_id           = var.aio_user_managed_identity_id
  subject             = "system:serviceaccount:${var.aio_namespace}:aio-dataflow"
}
