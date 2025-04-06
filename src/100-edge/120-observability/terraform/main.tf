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

module "rule_associations_obs" {
  source                           = "./modules/rule-associations-obs"
  arc_connected_cluster            = var.arc_connected_cluster
  aio_azure_monitor_workspace      = var.aio_azure_monitor_workspace
  aio_metrics_data_collection_rule = var.aio_metrics_data_collection_rule
  aio_logs_data_collection_rule    = var.aio_logs_data_collection_rule
  aio_resource_group               = var.resource_group
  scrape_interval                  = var.scrape_interval
}
