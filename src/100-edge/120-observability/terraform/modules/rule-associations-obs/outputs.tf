output "metrics_data_collection_rule_association" {
  description = "The metrics data collection rule association resource."
  value = {
    id   = azurerm_monitor_data_collection_rule_association.metrics_data_collection_rule_association.id
    name = azurerm_monitor_data_collection_rule_association.metrics_data_collection_rule_association.name
  }
}

output "logs_data_collection_rule_association" {
  description = "The logs data collection rule association resource."
  value = {
    id   = azurerm_monitor_data_collection_rule_association.logs_data_collection_rule_association.id
    name = azurerm_monitor_data_collection_rule_association.logs_data_collection_rule_association.name
  }
}
