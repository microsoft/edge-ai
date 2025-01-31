/**
 * # Cluster Extensions for Observability
 *
 * Creates the cluster extensions required to expose cluster and container metrics.
 */

locals {
  azure_monitor_workspace_id = "${var.resource_group_id}/providers/microsoft.monitor/accounts/${var.azure_monitor_workspace_name}"
  log_analytics_workspace_id = "${var.resource_group_id}/providers/microsoft.operationalinsights/workspaces/${var.log_analytics_workspace_name}"
  grafana_id                 = "${var.resource_group_id}/providers/Microsoft.Dashboard/grafana/connectedClusters/${var.grafana_name}"
}

resource "azurerm_kubernetes_cluster_extension" "container_metrics" {
  name           = "azuremonitor-metrics"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "Microsoft.AzureMonitor.Containers.Metrics"
  configuration_settings = {
    "azure-monitor-workspace-resource-id" = local.azure_monitor_workspace_id
    "grafana-resource-id"                 = local.grafana_id
  }
}

resource "azurerm_kubernetes_cluster_extension" "container_logs" {
  name           = "azuremonitor-containers"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "Microsoft.AzureMonitor.Containers"
  configuration_settings = {
    "logAnalyticsWorkspaceResourceID" = local.log_analytics_workspace_id
  }
}
