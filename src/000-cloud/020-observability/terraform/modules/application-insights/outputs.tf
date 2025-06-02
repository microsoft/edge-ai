/*
 * Application Insights Outputs
 */

output "application_insights" {
  description = "The Application Insights resource object with connection details for monitoring applications."
  value = {
    id                  = azurerm_application_insights.app_insights.id
    name                = azurerm_application_insights.app_insights.name
    instrumentation_key = azurerm_application_insights.app_insights.instrumentation_key
    connection_string   = azurerm_application_insights.app_insights.connection_string
    app_id              = azurerm_application_insights.app_insights.app_id
    resource_group_name = azurerm_application_insights.app_insights.resource_group_name
    location            = azurerm_application_insights.app_insights.location
    application_type    = azurerm_application_insights.app_insights.application_type
    workspace_id        = azurerm_application_insights.app_insights.workspace_id
    retention_in_days   = azurerm_application_insights.app_insights.retention_in_days
  }
  sensitive = true
}
