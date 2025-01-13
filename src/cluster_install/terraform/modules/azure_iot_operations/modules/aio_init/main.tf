/**
 * # Azure IoT Enablement Module
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.
 *
 */

locals {
  default_storage_class    = var.edge_storage_accelerator.faultToleranceEnabled ? "acstor-arccontainerstorage-storage-pool" : "default,local-path"
  kubernetes_storage_class = var.edge_storage_accelerator.diskStorageClass != "" ? var.edge_storage_accelerator.diskStorageClass : local.default_storage_class

  container_storage_settings = var.edge_storage_accelerator.faultToleranceEnabled ? {
    "edgeStorageConfiguration.create"               = "true"
    "feature.diskStorageClass"                      = local.kubernetes_storage_class
    "acstorConfiguration.create"                    = "true"
    "acstorConfiguration.properties.diskMountPoint" = "/mnt"
    } : {
    "edgeStorageConfiguration.create" = "true"
    "feature.diskStorageClass"        = local.kubernetes_storage_class
  }
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
  depends_on = [azurerm_arc_kubernetes_cluster_extension.platform]
}

resource "azurerm_arc_kubernetes_cluster_extension" "open_service_mesh" {
  name           = "open-service-mesh"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.openservicemesh"
  identity {
    type = "SystemAssigned"
  }
  version       = var.open_service_mesh.version
  release_train = var.open_service_mesh.train
  configuration_settings = {
    "osm.osm.enablePermissiveTrafficPolicy"       = "false"
    "osm.osm.featureFlags.enableWASMStats"        = "false"
    "osm.osm.configResyncInterval"                = "10s"
    "osm.osm.osmController.resource.requests.cpu" = "100m"
    "osm.osm.osmBootstrap.resource.requests.cpu"  = "100m"
    "osm.osm.injector.resource.requests.cpu"      = "100m"
  }
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
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.open_service_mesh, azurerm_arc_kubernetes_cluster_extension.platform]
}

resource "azurerm_arc_kubernetes_cluster_extension" "platform" {
  name           = "azure-iot-operations-platform"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.iotoperations.platform"
  identity {
    type = "SystemAssigned"
  }
  version           = var.platform.version
  release_train     = var.platform.train
  release_namespace = "cert-manager"
  configuration_settings = {
    "installCertManager"  = var.aio_platform_config.install_cert_manager ? "true" : "false"
    "installTrustManager" = var.aio_platform_config.install_trust_manager ? "true" : "false"
  }
}
