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

  // Keep ingestion public to avoid Application Insights billing feature lookup issues when enabling private endpoints
  internet_ingestion_enabled = true
  internet_query_enabled     = !var.should_enable_private_endpoints

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

module "application_insights" {
  source = "./modules/application-insights"

  resource_prefix            = var.resource_prefix
  environment                = var.environment
  instance_suffix            = var.instance
  location                   = var.location
  resource_group_name        = var.azmon_resource_group.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitor.id

  application_type  = var.app_insights_application_type
  retention_in_days = var.app_insights_retention_in_days

  // Keep ingestion public to avoid Application Insights billing feature lookup issues when enabling private endpoints
  internet_ingestion_enabled = true
  internet_query_enabled     = !var.should_enable_private_endpoints

  tags = var.tags
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
    command = "bash ${path.module}/../scripts/import-grafana-dashboards.sh"

    environment = {
      GRAFANA_NAME        = azurerm_dashboard_grafana.monitor.name
      RESOURCE_GROUP_NAME = var.azmon_resource_group.name
    }
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

  public_network_access_enabled = !var.should_enable_private_endpoints
}

/*
 * Private Link Configuration
 */

resource "azurerm_monitor_private_link_scope" "monitor_private_link_scope" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "ampls-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.azmon_resource_group.name

  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource "azurerm_monitor_private_link_scoped_service" "log_analytics" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "ampls-law-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.azmon_resource_group.name
  scope_name          = azurerm_monitor_private_link_scope.monitor_private_link_scope[0].name
  linked_resource_id  = azurerm_log_analytics_workspace.monitor.id
}

resource "azurerm_monitor_private_link_scoped_service" "application_insights" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "ampls-appi-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.azmon_resource_group.name
  scope_name          = azurerm_monitor_private_link_scope.monitor_private_link_scope[0].name
  linked_resource_id  = module.application_insights.application_insights.id
}

resource "azurerm_monitor_private_link_scoped_service" "data_collection_endpoint" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "ampls-dce-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.azmon_resource_group.name
  scope_name          = azurerm_monitor_private_link_scope.monitor_private_link_scope[0].name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.data_collection_endpoint.id
}

resource "azurerm_private_endpoint" "monitor_private_endpoint" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "pe-monitor-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.azmon_resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "monitor-private-connection"
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitor_private_link_scope[0].id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name = "monitor-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor_azure_com[0].id,
      azurerm_private_dns_zone.oms_opinsights_azure_com[0].id,
      azurerm_private_dns_zone.ods_opinsights_azure_com[0].id,
      azurerm_private_dns_zone.agentsvc_azure_automation_net[0].id,
      azurerm_private_dns_zone.blob_core_windows_net[0].id,
    ]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.log_analytics,
    azurerm_monitor_private_link_scoped_service.application_insights,
    azurerm_monitor_private_link_scoped_service.data_collection_endpoint,
  ]
}

// Private DNS zones for Azure Monitor private link
resource "azurerm_private_dns_zone" "monitor_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.azmon_resource_group.name
}

resource "azurerm_private_dns_zone" "oms_opinsights_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = var.azmon_resource_group.name
}

resource "azurerm_private_dns_zone" "ods_opinsights_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = var.azmon_resource_group.name
}

resource "azurerm_private_dns_zone" "agentsvc_azure_automation_net" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = var.azmon_resource_group.name
}

resource "azurerm_private_dns_zone" "blob_core_windows_net" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.azmon_resource_group.name
}

// Virtual network links for private DNS zones
resource "azurerm_private_dns_zone_virtual_network_link" "monitor_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                  = "vnet-link-monitor-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.azmon_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_azure_com[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms_opinsights_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                  = "vnet-link-oms-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.azmon_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.oms_opinsights_azure_com[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods_opinsights_azure_com" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                  = "vnet-link-ods-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.azmon_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.ods_opinsights_azure_com[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc_azure_automation_net" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                  = "vnet-link-agentsvc-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.azmon_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc_azure_automation_net[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_core_windows_net" {
  count = var.should_enable_private_endpoints ? 1 : 0

  name                  = "vnet-link-blob-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.azmon_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_core_windows_net[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

