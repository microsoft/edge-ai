/**
 * # Observability
 *
 * Creates a new Azure Monitor Workspace, Log Analytics Workspace and Azure Managed Grafana and assigns the required roles.
 */

locals {
  grafana_admin_principal_id = coalesce(var.grafana_admin_principal_id, data.azurerm_client_config.current.object_id)
}

data "azurerm_client_config" "current" {}

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.shared_resource_group_name,
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_resource_group" "this" {
  name = terraform_data.defer.output.resource_group_name
}

# Log Analytics Workspace
resource "azurerm_monitor_workspace" "monitor" {
  name                = "azmon-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
}

resource "azurerm_log_analytics_workspace" "monitor" {
  name                = "log-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"

  retention_in_days = var.log_retention_in_days
  daily_quota_gb    = var.daily_quota_in_gb

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_log_analytics_solution" "monitor" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.this.location
  resource_group_name   = data.azurerm_resource_group.this.name
  workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  workspace_name        = azurerm_log_analytics_workspace.monitor.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_dashboard_grafana" "monitor" {
  name                = "amg-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Standard"

  public_network_access_enabled     = true
  grafana_major_version             = var.grafana_major_version
  zone_redundancy_enabled           = false
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.monitor.id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.monitor.id
  role_definition_name = "Grafana Admin"
  principal_id         = local.grafana_admin_principal_id
  depends_on           = [azurerm_dashboard_grafana.monitor]

  count = var.grafana_admin_principal_id != "" ? 1 : 0
}

resource "azurerm_role_assignment" "grafana_logs_reader" {
  scope                = azurerm_log_analytics_workspace.monitor.id
  role_definition_name = "Reader"
  principal_id         = azurerm_dashboard_grafana.monitor.identity[0].principal_id
}

resource "azurerm_role_assignment" "grafana_metrics_reader" {
  scope                = azurerm_monitor_workspace.monitor.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.monitor.identity[0].principal_id
}

# import grafana dashboard for AIO
resource "terraform_data" "apply_scripts" {
  provisioner "local-exec" {
    command = "az grafana dashboard import -g ${data.azurerm_resource_group.this.name} -n ${azurerm_dashboard_grafana.monitor.name} --definition https://raw.githubusercontent.com/Azure/azure-iot-operations/refs/heads/main/samples/grafana-dashboard/aio.sample.json"
  }
}
