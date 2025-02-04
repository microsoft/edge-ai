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
  name      = "${var.resource_prefix}-arc"

  response_export_values = ["name", "id", "location"]
}

module "iot_ops_utility" {
  source = "../../terraform"

  aio_azure_managed_grafana   = data.azurerm_dashboard_grafana.aio
  aio_azure_monitor_workspace = data.azurerm_monitor_workspace.aio
  aio_log_analytics_workspace = data.azurerm_log_analytics_workspace.aio
  arc_connected_cluster       = data.azapi_resource.arc_connected_cluster.output
}
