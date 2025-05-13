/**
 * # Observability
 *
 * Creates a new Azure Monitor Workspace, Log Analytics Workspace and Azure Managed Grafana and assigns the required roles.
 * [Kubernetes Monitor](https://learn.microsoft.com/azure/azure-monitor/containers/kubernetes-monitoring-enable?tabs=terraform)
 */

locals {
  grafana_admin_principal_id      = coalesce(var.grafana_admin_principal_id, data.azurerm_client_config.current.object_id)
  grafana_monitoring_reader_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_monitor_workspace" "monitor" {
  name                = "azmon-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name
}

resource "azurerm_log_analytics_workspace" "monitor" {
  name                = "log-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  sku               = "PerGB2018"
  retention_in_days = var.log_retention_in_days
  daily_quota_gb    = var.daily_quota_in_gb

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_log_analytics_solution" "monitor" {
  solution_name       = "ContainerInsights"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  workspace_name        = azurerm_log_analytics_workspace.monitor.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_application_insights" "app_insights" {
  name                = "ai-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name
  workspace_id        = azurerm_log_analytics_workspace.monitor.id
  application_type    = "web"
}

resource "azurerm_dashboard_grafana" "monitor" {
  name                = "amg-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  sku                               = "Standard"
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
  count = var.grafana_admin_principal_id != "" ? 1 : 0

  scope                = azurerm_dashboard_grafana.monitor.id
  role_definition_name = "Grafana Admin"
  principal_id         = local.grafana_admin_principal_id
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

resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = local.grafana_monitoring_reader_scope
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.monitor.identity[0].principal_id
}

# import grafana dashboard for AIO
resource "terraform_data" "apply_scripts" {
  count = var.grafana_admin_principal_id != "" ? 1 : 0

  depends_on = [
    azurerm_role_assignment.grafana_admin,
    azurerm_role_assignment.grafana_logs_reader,
    azurerm_role_assignment.grafana_metrics_reader
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Import dashboards from local files
      for dashboard in ../../../src/000-cloud/020-observability/scripts/*.json; do
        az grafana dashboard import -g ${var.azmon_resource_group.name} -n ${azurerm_dashboard_grafana.monitor.name} --definition $dashboard
      done

      # Import dashboard from GitHub
      az grafana dashboard import -g ${var.azmon_resource_group.name} -n ${azurerm_dashboard_grafana.monitor.name} --definition https://raw.githubusercontent.com/Azure/azure-iot-operations/refs/heads/main/samples/grafana-dashboard/aio.sample.json
    EOT
  }
}

// ref: https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-rule-overview
// ref: https://github.com/microsoft/Docker-Provider/blob/4961414fc6fa72d072533cfbcdc9667f82d92f18/scripts/onboarding/aks/onboarding-msi-terraform/main.tf#L30
resource "azurerm_monitor_data_collection_rule" "logs_data_collection_rule" {
  name                = "dcr-${var.resource_prefix}-${var.environment}-logs-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  kind        = "Linux"
  description = "DCR for Azure Monitor Container Insights"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
      name                  = "logAnalytics"
    }
  }

  data_flow {
    streams      = var.logs_data_collection_rule_streams
    destinations = ["logAnalytics"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      streams        = var.logs_data_collection_rule_streams
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          namespaces             = var.logs_data_collection_rule_namespaces
          enableContainerLogV2   = true
        }
      })
    }
  }
}

// ref: https://github.com/Azure/prometheus-collector/blob/ecd8086c57e234bf0465dd82dbfb2f34ee3475f1/AddonTerraformTemplate/main.tf#L64
resource "azurerm_monitor_data_collection_rule" "metrics_data_collection_rule" {
  name                = "dcr-${var.resource_prefix}-${var.environment}-metrics-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.data_collection_endpoint.id

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.monitor.id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.data_collection_endpoint
  ]
}

// ref: https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-endpoint-overview?tabs=portal
// ref: https://github.com/Azure/prometheus-collector/blob/ecd8086c57e234bf0465dd82dbfb2f34ee3475f1/AddonTerraformTemplate/main.tf#L56
resource "azurerm_monitor_data_collection_endpoint" "data_collection_endpoint" {
  name                = "dce-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name

  kind = "Linux"
}
