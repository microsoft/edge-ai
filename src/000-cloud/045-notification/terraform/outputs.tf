/*
 * Logic App Outputs
 */

output "close_leak_endpoint" {
  description = "HTTP endpoint URL for closing active leak sessions"
  value       = azapi_resource_action.close_leak_callback_url.output.value
}

output "logic_app" {
  description = "Logic App workflow resource details"
  value = {
    id                    = azurerm_logic_app_workflow.teams_notification.id
    name                  = azurerm_logic_app_workflow.teams_notification.name
    identity_principal_id = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
  }
}
