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
