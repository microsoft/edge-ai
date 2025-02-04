/**
 * # IoT Ops Utilities Extensions
 *
 * Creates resources needed for additional utilities and features.
 */

module "cluster_extensions_obs" {
  source                      = "./modules/cluster-extensions-obs"
  arc_connected_cluster       = var.arc_connected_cluster
  aio_azure_monitor_workspace = var.aio_azure_monitor_workspace
  aio_log_analytics_workspace = var.aio_log_analytics_workspace
  aio_azure_managed_grafana   = var.aio_azure_managed_grafana
}
