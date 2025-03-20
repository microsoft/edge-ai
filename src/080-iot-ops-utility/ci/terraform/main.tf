# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_monitor_workspace" "aio" {
  name                = "azmon-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_log_analytics_workspace" "aio" {
  name                = "log-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_dashboard_grafana" "aio" {
  name                = "amg-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azapi_resource" "arc_connected_cluster" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id", "location"]
}

data "azurerm_monitor_data_collection_rule" "aio_metrics" {
  name                = "dcr-${var.resource_prefix}-${var.environment}-metrics-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_monitor_data_collection_rule" "aio_logs" {
  name                = "dcr-${var.resource_prefix}-${var.environment}-logs-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "iot_ops_utility" {
  source = "../../terraform"

  aio_azure_managed_grafana        = data.azurerm_dashboard_grafana.aio
  aio_azure_monitor_workspace      = data.azurerm_monitor_workspace.aio
  aio_log_analytics_workspace      = data.azurerm_log_analytics_workspace.aio
  aio_metrics_data_collection_rule = data.azurerm_monitor_data_collection_rule.aio_metrics
  aio_logs_data_collection_rule    = data.azurerm_monitor_data_collection_rule.aio_logs
  aio_resource_group               = data.azurerm_resource_group.aio
  arc_connected_cluster            = data.azapi_resource.arc_connected_cluster.output
}
