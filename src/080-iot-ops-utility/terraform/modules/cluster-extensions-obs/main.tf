/**
 * # Cluster Extensions for Observability
 *
 * Creates the cluster extensions required to expose cluster and container metrics.
 */

locals {
  ama_logs_domain = "opinsights.azure.com"
}

resource "azurerm_arc_kubernetes_cluster_extension" "container_metrics" {
  name           = "azuremonitor-metrics"
  cluster_id     = var.arc_connected_cluster.id
  extension_type = "Microsoft.AzureMonitor.Containers.Metrics"
  identity {
    type = "SystemAssigned"
  }
  configuration_settings = {
    "azure-monitor-workspace-resource-id" = var.aio_azure_monitor_workspace.id
    "grafana-resource-id"                 = var.aio_azure_managed_grafana.id
  }
}

resource "azurerm_arc_kubernetes_cluster_extension" "container_logs" {
  name              = "azuremonitor-containers"
  cluster_id        = var.arc_connected_cluster.id
  extension_type    = "Microsoft.AzureMonitor.Containers"
  release_train     = "Stable"
  release_namespace = "kube-system"
  identity {
    type = "SystemAssigned"
  }
  configuration_settings = {
    "logAnalyticsWorkspaceResourceID" = var.aio_log_analytics_workspace.id
    "omsagent.domain"                 = local.ama_logs_domain
    "amalogs.domain"                  = local.ama_logs_domain
    "omsagent.useAADAuth"             = "true"
    "amalogs.useAADAuth"              = "true"
  }
  configuration_protected_settings = {
    "amalogs.secret.wsid"  = var.aio_log_analytics_workspace.workspace_id
    "amalogs.secret.key"   = var.aio_log_analytics_workspace.primary_shared_key
    "omsagent.secret.wsid" = var.aio_log_analytics_workspace.workspace_id
    "omsagent.secret.key"  = var.aio_log_analytics_workspace.primary_shared_key
  }
}
