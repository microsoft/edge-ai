/**
 * # Azure Container Storage Extension Module
 *
 * Deploys the Azure Container Storage (ACSA) extension for Arc-enabled Kubernetes clusters.
 */

locals {
  default_storage_class    = var.container_storage_extension.fault_tolerance_enabled ? "acstor-arccontainerstorage-storage-pool" : "default,local-path"
  kubernetes_storage_class = var.container_storage_extension.disk_storage_class != "" ? var.container_storage_extension.disk_storage_class : local.default_storage_class

  container_storage_settings = var.container_storage_extension.fault_tolerance_enabled ? {
    "edgeStorageConfiguration.create"               = "true"
    "feature.diskStorageClass"                      = local.kubernetes_storage_class
    "acstorConfiguration.create"                    = "true"
    "acstorConfiguration.properties.diskMountPoint" = var.container_storage_extension.disk_mount_point
    } : {
    "edgeStorageConfiguration.create" = "true"
    "feature.diskStorageClass"        = local.kubernetes_storage_class
  }
}

resource "azurerm_arc_kubernetes_cluster_extension" "container_storage" {
  name           = "azure-arc-containerstorage"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.arc.containerstorage"
  identity {
    type = "SystemAssigned"
  }
  version                = var.container_storage_extension.version
  release_train          = var.container_storage_extension.train
  configuration_settings = local.container_storage_settings
}
