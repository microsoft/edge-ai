/**
 * # Notification
 *
 * Deploys an Azure Logic App that subscribes to Event Hub ALERT_DLQC events,
 * parses the leak detection payload, and posts messages directly to Microsoft Teams
 * using the Teams API Connection (OAuth connector). The Teams connection requires
 * user consent after deployment via the Azure Portal.
 */

locals {
  logic_app_name     = "la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}"
  eventhub_conn_name = "apicon-evhub-${var.resource_prefix}-${var.environment}-${var.instance}"
  teams_conn_name    = "apicon-teams-${var.resource_prefix}-${var.environment}-${var.instance}"
}

// ── Managed API Lookups ──────────────────────────────────────

data "azurerm_managed_api" "eventhub" {
  name     = "eventhubs"
  location = var.resource_group.location
}

data "azurerm_managed_api" "teams" {
  name     = "teams"
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

resource "azapi_resource" "teams_connection" {
  type      = "Microsoft.Web/connections@2016-06-01"
  name      = local.teams_conn_name
  location  = var.resource_group.location
  parent_id = var.resource_group.id
  tags      = var.tags

  schema_validation_enabled = false

  body = {
    properties = {
      api = {
        id = data.azurerm_managed_api.teams.id
      }
      displayName = "Teams"
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
      teams = {
        connectionId         = azapi_resource.teams_connection.id
        connectionName       = azapi_resource.teams_connection.name
        id                   = data.azurerm_managed_api.teams.id
        connectionProperties = {}
      }
    })
  }
}

// ── Workflow Trigger ─────────────────────────────────────────

resource "azurerm_logic_app_trigger_custom" "eventhub_trigger" {
  name         = "When_events_are_available_in_Event_Hub"
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
        contentType        = "application/octet-stream"
        consumerGroupName  = "$Default"
        maximumEventsCount = 50
      }
    }
    recurrence = {
      frequency = "Second"
      interval  = 5
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
          message_type  = { type = "string" }
          timestamp     = { type = "number" }
          source_device = { type = "string" }
          inference_result = {
            type = "object"
            properties = {
              model_name        = { type = "string" }
              model_type        = { type = "string" }
              confidence        = { type = "number" }
              inference_time_ms = { type = "number" }
              metadata = {
                type = "object"
                properties = {
                  backend        = { type = "string" }
                  inference_type = { type = "string" }
                  model_path     = { type = "string" }
                  request_id     = { type = "string" }
                }
              }
              predictions = {
                type = "array"
                items = {
                  type = "object"
                  properties = {
                    class      = { type = "string" }
                    confidence = { type = "number" }
                    bbox       = {}
                    severity   = { type = "string" }
                    metadata = {
                      type = "object"
                      properties = {
                        backend        = { type = "string" }
                        class_index    = { type = "integer" }
                        inference_type = { type = "string" }
                        model_name     = { type = "string" }
                      }
                    }
                  }
                }
              }
            }
          }
          enrichment = {
            type = "object"
            properties = {
              site          = { type = "string" }
              facility      = { type = "string" }
              business_unit = { type = "string" }
              alert_level   = { type = "string" }
              region        = { type = "string" }
              recommended_actions = {
                type  = "array"
                items = { type = "string" }
              }
            }
          }
        }
      }
    }
    runAfter = {}
  })
}

resource "azurerm_logic_app_action_custom" "post_teams_message" {
  name         = "Post_message_in_a_chat_or_channel"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['teams']['connectionId']"
        }
      }
      method = "post"
      body = {
        recipient = var.teams_recipient_id
        messageBody = join("", [
          "<p class=\"editor-paragraph\"><strong>Leak Detection Alert</strong></p><br>",
          "<p class=\"editor-paragraph\"><strong>Source:</strong> @{body('Parse_Leak_Event')?['source_device']}</p>",
          "<p class=\"editor-paragraph\"><strong>Timestamp:</strong> @{body('Parse_Leak_Event')?['timestamp']}</p>",
          "<p class=\"editor-paragraph\"><strong>Model:</strong> @{body('Parse_Leak_Event')?['inference_result']?['model_name']} (@{body('Parse_Leak_Event')?['inference_result']?['model_type']})</p>",
          "<p class=\"editor-paragraph\"><strong>Confidence:</strong> @{body('Parse_Leak_Event')?['inference_result']?['confidence']}</p>",
          "<p class=\"editor-paragraph\"><strong>Predictions:</strong> @{body('Parse_Leak_Event')?['inference_result']?['predictions']}</p>",
          "<p class=\"editor-paragraph\"><strong>Alert Level:</strong> @{body('Parse_Leak_Event')?['enrichment']?['alert_level']}</p>",
          "<p class=\"editor-paragraph\"><strong>Site:</strong> @{body('Parse_Leak_Event')?['enrichment']?['site']} / @{body('Parse_Leak_Event')?['enrichment']?['facility']}</p>",
          "<p class=\"editor-paragraph\"><strong>Recommended Actions:</strong> @{body('Parse_Leak_Event')?['enrichment']?['recommended_actions']}</p>",
        ])
      }
      path = "/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent('${var.teams_post_location}')}"
    }
    runAfter = {
      Parse_Leak_Event = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.parse_payload]
}

// ── Role Assignments ─────────────────────────────────────────

resource "azurerm_role_assignment" "eventhub_data_receiver" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}
