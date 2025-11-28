output "azure_monitor_workspace" {
  value = azurerm_monitor_workspace.monitor
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.monitor

  sensitive = true
}

output "azure_managed_grafana" {
  value = azurerm_dashboard_grafana.monitor
}

output "logs_data_collection_rule" {
  value = azurerm_monitor_data_collection_rule.logs_data_collection_rule

  sensitive = true
}

output "metrics_data_collection_rule" {
  value = azurerm_monitor_data_collection_rule.metrics_data_collection_rule

  sensitive = true
}

output "data_collection_endpoint" {
  value = azurerm_monitor_data_collection_endpoint.data_collection_endpoint
}

output "application_insights" {
  description = "The Application Insights resource object with connection details for monitoring applications."
  value       = module.application_insights.application_insights
  sensitive   = true
}

/*
 * Private Endpoint Outputs
 */

output "monitor_private_link_scope" {
  description = "The Azure Monitor Private Link Scope for private endpoint connections."
  value       = try(azurerm_monitor_private_link_scope.monitor_private_link_scope[0], null)
}

output "monitor_private_endpoint" {
  description = "The private endpoint for Azure Monitor services."
  value = try({
    id                   = azurerm_private_endpoint.monitor_private_endpoint[0].id
    name                 = azurerm_private_endpoint.monitor_private_endpoint[0].name
    private_ip_address   = azurerm_private_endpoint.monitor_private_endpoint[0].private_service_connection[0].private_ip_address
    network_interface_id = azurerm_private_endpoint.monitor_private_endpoint[0].network_interface[0].id
    custom_dns_configs   = azurerm_private_endpoint.monitor_private_endpoint[0].custom_dns_configs
  }, null)
}

output "private_dns_zones" {
  description = "The private DNS zones for Azure Monitor private link."
  value = try({
    monitor_azure_com             = azurerm_private_dns_zone.monitor_azure_com[0]
    oms_opinsights_azure_com      = azurerm_private_dns_zone.oms_opinsights_azure_com[0]
    ods_opinsights_azure_com      = azurerm_private_dns_zone.ods_opinsights_azure_com[0]
    agentsvc_azure_automation_net = azurerm_private_dns_zone.agentsvc_azure_automation_net[0]
    blob_core_windows_net         = azurerm_private_dns_zone.blob_core_windows_net[0]
  }, null)
}

output "blob_private_dns_zone" {
  description = "The blob private DNS zone object for sharing with storage account component."
  value = try({
    id   = azurerm_private_dns_zone.blob_core_windows_net[0].id
    name = azurerm_private_dns_zone.blob_core_windows_net[0].name
  }, null)
}
