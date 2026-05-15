/*
 * Logic App Outputs
 */

output "close_logic_app" {
  description = "Close session Logic App workflow resource details."
  value = {
    id                    = azurerm_logic_app_workflow.close_session.id
    name                  = azurerm_logic_app_workflow.close_session.name
    identity_principal_id = azurerm_logic_app_workflow.close_session.identity[0].principal_id
  }
}

output "close_session_endpoint" {
  description = "HTTP endpoint URL for closing active event sessions."
  value       = azapi_resource_action.close_session_callback_url.output.value
  sensitive   = true
}

output "logic_app" {
  description = "Notification Logic App workflow resource details."
  value = {
    id                    = azurerm_logic_app_workflow.teams_notification.id
    name                  = azurerm_logic_app_workflow.teams_notification.name
    identity_principal_id = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
  }
}

/*
 * Storage Outputs
 */

output "storage_account" {
  description = "Storage account used for event session state tracking via Table Storage."
  value = {
    id   = local.storage_account_id
    name = local.storage_account_name
  }
}
