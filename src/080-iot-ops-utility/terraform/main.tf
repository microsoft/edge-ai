/**
 * # IoT Ops Utilities Extensions
 *
 * Creates resources needed for additional utilities and features.
 */

locals {
  connected_cluster_name       = coalesce(var.connected_cluster_name, "${var.resource_prefix}-arc")
  azure_monitor_workspace_name = coalesce(var.azure_monitor_workspace_name, "azmon-${var.resource_prefix}-${var.environment}-${var.instance}")
  log_analytics_workspace_name = coalesce(var.log_analytics_workspace_name, "log-${var.resource_prefix}-${var.environment}-${var.instance}")
  grafana_name                 = coalesce(var.grafana_name, "amg-${var.resource_prefix}-${var.environment}-${var.instance}")
  arc_connected_cluster_id     = "${data.azurerm_resource_group.this.id}/providers/Microsoft.Kubernetes/connectedClusters/${local.connected_cluster_name}"
}

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_resource_group" "this" {
  name = terraform_data.defer.output.resource_group_name
}

module "cluster_extensions_obs" {
  source                       = "./modules/cluster-extensions-obs"
  resource_group_id            = data.azurerm_resource_group.this.id
  arc_connected_cluster_id     = local.arc_connected_cluster_id
  azure_monitor_workspace_name = local.azure_monitor_workspace_name
  log_analytics_workspace_name = local.log_analytics_workspace_name
  grafana_name                 = local.grafana_name
}
