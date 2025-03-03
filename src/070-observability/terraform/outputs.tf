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
