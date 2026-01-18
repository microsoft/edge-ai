/**
 * # Arc Extensions
 *
 * Deploys foundational Arc-enabled Kubernetes cluster extensions including
 * cert-manager and Azure Container Storage (ACSA).
 */

module "cert_manager_extension" {
  count = var.arc_extensions.cert_manager_extension.enabled ? 1 : 0

  source = "./modules/cert-manager"

  arc_connected_cluster_id = var.arc_connected_cluster.id
  cert_manager_extension   = var.arc_extensions.cert_manager_extension
}

module "container_storage_extension" {
  count = var.arc_extensions.container_storage_extension.enabled ? 1 : 0

  source = "./modules/container-storage"

  depends_on = [module.cert_manager_extension]

  arc_connected_cluster_id    = var.arc_connected_cluster.id
  container_storage_extension = var.arc_extensions.container_storage_extension
}
