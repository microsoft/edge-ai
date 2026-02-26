/**
 * # Notification
 *
 * Deploys Azure Logic Apps for leak detection notifications with state tracking.
 * The primary workflow subscribes to Event Hub ALERT_DLQC events, deduplicates
 * using Azure Table Storage, and posts new-leak alerts to Microsoft Teams.
 * A secondary workflow provides an HTTP endpoint to close active leak sessions.
 * The Teams connection requires user consent after deployment via the Azure Portal.
 */

locals {
  close_logic_app_name = "la-${var.resource_prefix}-leak-close-${var.environment}-${var.instance}"
  eventhub_conn_name   = "apicon-evhub-${var.resource_prefix}-${var.environment}-${var.instance}"
  logic_app_name       = "la-${var.resource_prefix}-leak-notify-${var.environment}-${var.instance}"
  table_endpoint       = "https://${var.storage_account.name}.table.core.windows.net"
  table_name           = "leaksessions"
  teams_conn_name      = "apicon-teams-${var.resource_prefix}-${var.environment}-${var.instance}"
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

// ── Azure Table Storage ──────────────────────────────────────

resource "azapi_resource" "leak_sessions_table" {
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01"
  name      = local.table_name
  parent_id = "${var.storage_account.id}/tableServices/default"
}

// ── API Connections ──────────────────────────────────────────

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

// ── Primary Logic App: Leak Notification ─────────────────────

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

// ── Primary Workflow Trigger ─────────────────────────────────

resource "azurerm_logic_app_trigger_custom" "eventhub_trigger" {
  name         = "When_events_are_available_in_Event_Hub"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type = "ApiConnection"
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

// ── Close Logic App: Leak Resolution ─────────────────────────

resource "azurerm_logic_app_workflow" "close_leak" {
  name                = local.close_logic_app_name
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
      teams = {
        connectionId         = azapi_resource.teams_connection.id
        connectionName       = azapi_resource.teams_connection.name
        id                   = data.azurerm_managed_api.teams.id
        connectionProperties = {}
      }
    })
  }
}

resource "azurerm_logic_app_trigger_custom" "close_leak_trigger" {
  name         = "Close_Leak_Request"
  logic_app_id = azurerm_logic_app_workflow.close_leak.id

  body = jsonencode({
    type = "Request"
    kind = "Http"
    inputs = {
      method = "GET"
      schema = {}
    }
  })
}

// ── Close Logic App Callback URL ─────────────────────────────

resource "azapi_resource_action" "close_leak_callback_url" {
  type                   = "Microsoft.Logic/workflows/triggers@2019-05-01"
  resource_id            = "${azurerm_logic_app_workflow.close_leak.id}/triggers/${azurerm_logic_app_trigger_custom.close_leak_trigger.name}"
  action                 = "listCallbackUrl"
  response_export_values = ["value"]
}

// ── Primary Workflow Actions ─────────────────────────────────

resource "azurerm_logic_app_action_custom" "for_each_event" {
  name         = "For_Each_Event"
  logic_app_id = azurerm_logic_app_workflow.teams_notification.id

  body = jsonencode({
    type             = "Foreach"
    foreach          = "@triggerBody()"
    operationOptions = "Sequential"
    actions = {
      Parse_Leak_Event = {
        type = "ParseJson"
        inputs = {
          content = "@base64ToString(items('For_Each_Event')?['ContentData'])"
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
      }
      Get_Active_Leak = {
        type = "Http"
        inputs = {
          method = "GET"
          uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{body('Parse_Leak_Event')?['source_device']}',RowKey='active')"
          headers = {
            Accept         = "application/json;odata=nometadata"
            "x-ms-version" = "2020-12-06"
          }
          authentication = {
            type     = "ManagedServiceIdentity"
            audience = "https://storage.azure.com/"
          }
        }
        runAfter = {
          Parse_Leak_Event = ["Succeeded"]
        }
      }
      Check_New_Leak = {
        type = "If"
        expression = {
          and = [
            {
              equals = [
                "@outputs('Get_Active_Leak')['statusCode']",
                404
              ]
            }
          ]
        }
        actions = {
          Insert_Entity = {
            type = "Http"
            inputs = {
              method = "POST"
              uri    = "${local.table_endpoint}/${local.table_name}"
              headers = {
                "Content-Type" = "application/json"
                Accept         = "application/json;odata=nometadata"
                "x-ms-version" = "2020-12-06"
              }
              body = {
                PartitionKey    = "@{body('Parse_Leak_Event')?['source_device']}"
                RowKey          = "active"
                FirstDetectedAt = "@{utcNow()}"
                LastEventAt     = "@{utcNow()}"
                EventCount      = 1
                Confidence      = "@{body('Parse_Leak_Event')?['inference_result']?['confidence']}"
                AlertLevel      = "@{coalesce(body('Parse_Leak_Event')?['enrichment']?['alert_level'], 'Unknown')}"
              }
              authentication = {
                type     = "ManagedServiceIdentity"
                audience = "https://storage.azure.com/"
              }
            }
            runAfter = {}
          }
          Post_Teams_Notification = {
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
                  "<p><strong>🚨 Leak Detection Alert</strong></p>",
                  "<p><strong>Device:</strong> @{body('Parse_Leak_Event')?['source_device']}</p>",
                  "<p><strong>Detected At:</strong> @{utcNow()}</p>",
                  "<p><strong>Confidence:</strong> @{body('Parse_Leak_Event')?['inference_result']?['confidence']}</p>",
                  "<p><strong>Model:</strong> @{body('Parse_Leak_Event')?['inference_result']?['model_name']}</p>",
                  "<p><strong>Alert Level:</strong> @{coalesce(body('Parse_Leak_Event')?['enrichment']?['alert_level'], 'Unknown')}</p>",
                  "<p><strong>Site:</strong> @{coalesce(body('Parse_Leak_Event')?['enrichment']?['site'], 'Unknown')} / @{coalesce(body('Parse_Leak_Event')?['enrichment']?['facility'], 'Unknown')}</p>",
                  "<p><a href=\"${azapi_resource_action.close_leak_callback_url.output.value}&device=@{encodeUriComponent(body('Parse_Leak_Event')?['source_device'])}\">✅ Close Leak</a></p>",
                ])
              }
              path = "/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent('${var.teams_post_location}')}"
            }
            runAfter = {
              Insert_Entity = ["Succeeded"]
            }
          }
        }
        else = {
          actions = {
            Update_Entity = {
              type = "Http"
              inputs = {
                method = "PATCH"
                uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{body('Parse_Leak_Event')?['source_device']}',RowKey='active')"
                headers = {
                  "Content-Type" = "application/json"
                  Accept         = "application/json;odata=nometadata"
                  "x-ms-version" = "2020-12-06"
                  "If-Match"     = "*"
                }
                body = {
                  LastEventAt = "@{utcNow()}"
                  EventCount  = "@{add(int(body('Get_Active_Leak')?['EventCount']), 1)}"
                  Confidence  = "@{if(greater(float(body('Parse_Leak_Event')?['inference_result']?['confidence']), float(body('Get_Active_Leak')?['Confidence'])), body('Parse_Leak_Event')?['inference_result']?['confidence'], body('Get_Active_Leak')?['Confidence'])}"
                }
                authentication = {
                  type     = "ManagedServiceIdentity"
                  audience = "https://storage.azure.com/"
                }
              }
              runAfter = {}
            }
          }
        }
        runAfter = {
          Get_Active_Leak = ["Succeeded", "Failed"]
        }
      }
    }
    runAfter = {}
  })
}

// ── Close Workflow Actions ───────────────────────────────────

resource "azurerm_logic_app_action_custom" "get_leak_session" {
  name         = "Get_Leak_Session"
  logic_app_id = azurerm_logic_app_workflow.close_leak.id

  body = jsonencode({
    type = "Http"
    inputs = {
      method = "GET"
      uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{triggerOutputs()['queries']['device']}',RowKey='active')"
      headers = {
        Accept         = "application/json;odata=nometadata"
        "x-ms-version" = "2020-12-06"
      }
      authentication = {
        type     = "ManagedServiceIdentity"
        audience = "https://storage.azure.com/"
      }
    }
    runAfter = {}
  })
}

resource "azurerm_logic_app_action_custom" "delete_entity" {
  name         = "Delete_Entity"
  logic_app_id = azurerm_logic_app_workflow.close_leak.id

  body = jsonencode({
    type = "Http"
    inputs = {
      method = "DELETE"
      uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{triggerOutputs()['queries']['device']}',RowKey='active')"
      headers = {
        Accept         = "application/json;odata=nometadata"
        "x-ms-version" = "2020-12-06"
        "If-Match"     = "*"
      }
      authentication = {
        type     = "ManagedServiceIdentity"
        audience = "https://storage.azure.com/"
      }
    }
    runAfter = {
      Get_Leak_Session = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.get_leak_session]
}

resource "azurerm_logic_app_action_custom" "post_closure_summary" {
  name         = "Post_Closure_Summary"
  logic_app_id = azurerm_logic_app_workflow.close_leak.id

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
          "<p><strong>✅ Leak Resolved</strong></p>",
          "<p><strong>Device:</strong> @{triggerOutputs()['queries']['device']}</p>",
          "<p><strong>Active From:</strong> @{body('Get_Leak_Session')?['FirstDetectedAt']}</p>",
          "<p><strong>Active Until:</strong> @{body('Get_Leak_Session')?['LastEventAt']}</p>",
          "<p><strong>Total Events:</strong> @{body('Get_Leak_Session')?['EventCount']}</p>",
        ])
      }
      path = "/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent('${var.teams_post_location}')}"
    }
    runAfter = {
      Delete_Entity = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.delete_entity]
}

resource "azurerm_logic_app_action_custom" "close_response" {
  name         = "Response"
  logic_app_id = azurerm_logic_app_workflow.close_leak.id

  body = jsonencode({
    type = "Response"
    kind = "Http"
    inputs = {
      statusCode = "@{if(equals(actions('Delete_Entity')['status'], 'Succeeded'), 200, if(equals(actions('Get_Leak_Session')['status'], 'Failed'), 404, 500))}"
      headers = {
        "Content-Type" = "text/plain"
      }
      body = "@{if(equals(actions('Delete_Entity')['status'], 'Succeeded'), 'Leak closed', if(equals(actions('Get_Leak_Session')['status'], 'Failed'), 'No active leak found for this device', 'Failed to close leak'))}"
    }
    runAfter = {
      Post_Closure_Summary = ["Succeeded", "Failed", "Skipped", "TimedOut"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.post_closure_summary]
}

// ── Role Assignments ─────────────────────────────────────────

resource "azurerm_role_assignment" "eventhub_data_receiver" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_table_data_contributor" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.storage_account.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}

resource "azurerm_role_assignment" "close_leak_storage_table_data_contributor" {
  count = var.should_assign_roles ? 1 : 0

  scope                = var.storage_account.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_logic_app_workflow.close_leak.identity[0].principal_id
}
