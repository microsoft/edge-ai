/**
 * # Notification
 *
 * Deploys an Azure Logic App that subscribes to Event Hub ALERT_DLQC events,
 * derives severity from confidence_level, composes an Adaptive Card, and posts
 * it to a Microsoft Teams Incoming Webhook URL retrieved from Key Vault.
 */

locals {
  logic_app_name     = "la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}"
  eventhub_conn_name = "apicon-evhub-${var.resource_prefix}-${var.environment}-${var.instance}"
  keyvault_conn_name = "apicon-kv-${var.resource_prefix}-${var.environment}-${var.instance}"
}

// ── Managed API Lookups ──────────────────────────────────────

data "azurerm_managed_api" "eventhub" {
  name     = "eventhubs"
  location = var.resource_group.location
}

data "azurerm_managed_api" "keyvault" {
  name     = "keyvault"
  location = var.resource_group.location
}

// ── API Connections (Managed Identity) ───────────────────────

resource "azapi_resource" "eventhub_connection" {
  type      = "Microsoft.Web/connections@2016-06-01"
  name      = local.eventhub_conn_name
  location  = var.resource_group.location
  parent_id = var.resource_group.id
  tags      = var.tags

  schema_validation_enabled = false

  body = {
    properties = {
      api = {
        id = data.azurerm_managed_api.eventhub.id
      }
      displayName = "Event Hub (Managed Identity)"
      parameterValueSet = {
        name = "managedIdentityAuth"
        values = {
          namespaceEndpoint = {
            value = "sb://${var.eventhub_namespace.name}.servicebus.windows.net/"
          }
        }
      }
    }
  }
}

resource "azapi_resource" "keyvault_connection" {
  type      = "Microsoft.Web/connections@2016-06-01"
  name      = local.keyvault_conn_name
  location  = var.resource_group.location
  parent_id = var.resource_group.id
  tags      = var.tags

  schema_validation_enabled = false

  body = {
    properties = {
      api = {
        id = data.azurerm_managed_api.keyvault.id
      }
      displayName = "Key Vault (Managed Identity)"
      parameterValueSet = {
        name = "oauthMI"
        values = {
          vaultName = {
            value = var.key_vault.name
          }
        }
      }
    }
  }
}

// ── Logic App Workflow ───────────────────────────────────────

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

  parameters = {
    "$connections" = jsonencode({
      eventhubs = {
        connectionId   = azapi_resource.eventhub_connection.id
        connectionName = azapi_resource.eventhub_connection.name
        id             = data.azurerm_managed_api.eventhub.id
        connectionProperties = {
          authentication = {
            type = "ManagedServiceIdentity"
          }
        }
      }
      keyvault = {
        connectionId   = azapi_resource.keyvault_connection.id
        connectionName = azapi_resource.keyvault_connection.name
        id             = data.azurerm_managed_api.keyvault.id
        connectionProperties = {
          authentication = {
            type = "ManagedServiceIdentity"
          }
        }
      }
    })
  }
}

// ── Workflow Trigger ─────────────────────────────────────────

resource "azurerm_logic_app_trigger_custom" "eventhub_trigger" {
  name         = "When_events_arrive_in_Event_Hub"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type    = "ApiConnection"
    splitOn = "@triggerBody()"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['eventhubs']['connectionId']"
        }
      }
      method = "get"
      path   = "/@{encodeURIComponent('${var.eventhub_name}')}/events/batch/head"
      queries = {
        contentType        = "application/json"
        consumerGroupName  = "$Default"
        maximumEventsCount = 50
      }
    }
    recurrence = {
      frequency = "Minute"
      interval  = 1
    }
  })
}

// ── Workflow Actions ─────────────────────────────────────────

resource "azurerm_logic_app_action_custom" "parse_payload" {
  name         = "Parse_Leak_Event"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type = "ParseJson"
    inputs = {
      content = "@base64ToString(triggerBody()?['ContentData'])"
      schema = {
        type = "object"
        properties = {
          confidence_level = { type = "number" }
          timestamp        = { type = "string" }
          device_id        = { type = "string" }
          location         = { type = "string" }
          alert_type       = { type = "string" }
          message          = { type = "string" }
        }
      }
    }
    runAfter = {}
  })
}

resource "azurerm_logic_app_action_custom" "derive_severity" {
  name         = "Derive_Severity"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type   = "Compose"
    inputs = "@if(greaterOrEquals(body('Parse_Leak_Event')?['confidence_level'], 0.8), 'High', if(greaterOrEquals(body('Parse_Leak_Event')?['confidence_level'], 0.5), 'Medium', 'Low'))"
    runAfter = {
      Parse_Leak_Event = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.parse_payload]
}

resource "azurerm_logic_app_action_custom" "get_webhook_secret" {
  name         = "Get_Teams_Webhook_URL"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['keyvault']['connectionId']"
        }
      }
      method = "get"
      path   = "/secrets/@{encodeURIComponent('${var.teams_webhook_secret_name}')}/value"
    }
    runAfter = {
      Parse_Leak_Event = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.parse_payload]
}

resource "azurerm_logic_app_action_custom" "post_teams_notification" {
  name         = "Post_Teams_Notification"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type = "Http"
    inputs = {
      method = "POST"
      uri    = "@body('Get_Teams_Webhook_URL')?['value']"
      headers = {
        "Content-Type" = "application/json"
      }
      body = {
        type = "message"
        attachments = [
          {
            contentType = "application/vnd.microsoft.card.adaptive"
            content = {
              "$schema" = "http://adaptivecards.io/schemas/adaptive-card.json"
              type      = "AdaptiveCard"
              version   = "1.4"
              body = [
                {
                  type   = "TextBlock"
                  text   = "🚨 Leak Detection Alert"
                  weight = "Bolder"
                  size   = "Large"
                  color  = "Attention"
                },
                {
                  type   = "TextBlock"
                  text   = "Severity: @{outputs('Derive_Severity')}"
                  weight = "Bolder"
                },
                {
                  type = "FactSet"
                  facts = [
                    { title = "Device", value = "@{body('Parse_Leak_Event')?['device_id']}" },
                    { title = "Location", value = "@{body('Parse_Leak_Event')?['location']}" },
                    { title = "Confidence", value = "@{body('Parse_Leak_Event')?['confidence_level']}" },
                    { title = "Alert Type", value = "@{body('Parse_Leak_Event')?['alert_type']}" },
                    { title = "Time", value = "@{body('Parse_Leak_Event')?['timestamp']}" },
                  ]
                },
                {
                  type = "TextBlock"
                  text = "@{coalesce(body('Parse_Leak_Event')?['message'], 'No additional details')}"
                  wrap = true
                },
              ]
            }
          },
        ]
      }
    }
    runAfter = {
      Derive_Severity       = ["Succeeded"]
      Get_Teams_Webhook_URL = ["Succeeded"]
    }
  })

  depends_on = [
    azurerm_logic_app_action_custom.derive_severity,
    azurerm_logic_app_action_custom.get_webhook_secret,
  ]
}

// ── Role Assignments ─────────────────────────────────────────

resource "azurerm_role_assignment" "eventhub_data_receiver" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}
