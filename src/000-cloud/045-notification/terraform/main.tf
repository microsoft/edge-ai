/**
 * # Notification
 *
 * Deploys an Azure Logic App that subscribes to Event Hub ALERT_DLQC events,
 * derives severity from confidence_level, composes an Adaptive Card, and posts
 * it to a Microsoft Teams Incoming Webhook URL retrieved from Key Vault.
 */

locals {
  logic_app_name = "la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}"
}

resource "azurerm_logic_app_workflow" "teams_notification" {
  name                = local.logic_app_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }
}

// Event Hubs Data Receiver role for the Logic App managed identity
resource "azurerm_role_assignment" "eventhub_data_receiver" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}

// Key Vault Secrets User role for the Logic App managed identity
resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}
