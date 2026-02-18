/*
 * Logic App Outputs
 */

output "logic_app" {
  description = "Logic App workflow resource details"
  value = {
    id                    = azurerm_logic_app_workflow.teams_notification.id
    name                  = azurerm_logic_app_workflow.teams_notification.name
    identity_principal_id = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
  }
}
