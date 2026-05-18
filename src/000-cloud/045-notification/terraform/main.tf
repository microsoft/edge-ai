/**
 * # Notification
 *
 * Deploys Azure Logic Apps for Event Hub event notifications with state deduplication.
 * The primary workflow subscribes to Event Hub events, deduplicates using Azure Table
 * Storage, and posts new-event alerts to Microsoft Teams.
 * A secondary workflow provides an HTTP endpoint to close active event sessions.
 * The Teams connection requires user consent after deployment via the Azure Portal.
 */

locals {
  storage_account_id   = var.storage_account.id
  storage_account_name = var.storage_account.name

  close_logic_app_name = "la-${var.resource_prefix}-${var.close_purpose}-${var.environment}-${var.instance}"
  eventhub_conn_name   = "conn-evh-${var.resource_prefix}-${var.environment}-${var.instance}"
  logic_app_name       = "la-${var.resource_prefix}-${var.notification_purpose}-${var.environment}-${var.instance}"
  table_endpoint       = "https://${local.storage_account_name}.table.core.windows.net"
  table_name           = var.table_name
  teams_conn_name      = "conn-teams-${var.resource_prefix}-${var.environment}-${var.instance}"

  default_insert_entity_body = merge({
    PartitionKey    = "@{body('Parse_Event')?['${var.partition_key_field}']}"
    RowKey          = "active"
    FirstDetectedAt = "@{utcNow()}"
    LastEventAt     = "@{utcNow()}"
    EventCount      = 1
  }, var.extra_entity_fields)

  default_update_entity_body = {
    LastEventAt = "@{utcNow()}"
    EventCount  = "@{add(int(body('Get_Active_Session')?['EventCount']), 1)}"
  }

  insert_entity_body = coalesce(var.insert_entity_body, local.default_insert_entity_body)
  update_entity_body = coalesce(var.update_entity_body, local.default_update_entity_body)

  teams_notification_recipient = var.teams_post_location == "Channel" ? jsonencode({
    groupId   = var.teams_group_id
    channelId = var.teams_recipient_id
  }) : jsonencode(var.teams_recipient_id)
}

// ── Managed API Lookups ──────────────────────────────────────

data "azurerm_managed_api" "eventhub" {
  name     = "eventhubs"
  location = var.location
}

data "azurerm_managed_api" "teams" {
  name     = "teams"
  location = var.location
}

// ── Azure Table Storage ──────────────────────────────────────

resource "azapi_resource" "event_sessions_table" {
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01"
  name      = local.table_name
  parent_id = "${local.storage_account_id}/tableServices/default"
}

// ── API Connections ──────────────────────────────────────────

resource "azapi_resource" "eventhub_connection" {
  type      = "Microsoft.Web/connections@2016-06-01"
  name      = local.eventhub_conn_name
  location  = var.location
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
  location  = var.location
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

// ── Primary Logic App: Event Notification ─────────────────────

resource "azurerm_logic_app_workflow" "teams_notification" {
  name                = local.logic_app_name
  location            = var.location
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
        consumerGroupName  = var.eventhub_consumer_group
        maximumEventsCount = var.maximum_events_count
      }
    }
    recurrence = {
      frequency = "Second"
      interval  = var.polling_interval
    }
  })
}

// ── Close Logic App: Session Resolution ─────────────────────

resource "azurerm_logic_app_workflow" "close_session" {
  name                = local.close_logic_app_name
  location            = var.location
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

resource "azurerm_logic_app_trigger_custom" "close_session_trigger" {
  name         = "Close_Session_Request"
  logic_app_id = azurerm_logic_app_workflow.close_session.id

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

resource "azapi_resource_action" "close_session_callback_url" {
  type                   = "Microsoft.Logic/workflows/triggers@2019-05-01"
  resource_id            = "${azurerm_logic_app_workflow.close_session.id}/triggers/${azurerm_logic_app_trigger_custom.close_session_trigger.name}"
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
      Parse_Event = {
        type = "ParseJson"
        inputs = {
          content = "@base64ToString(items('For_Each_Event')?['ContentData'])"
          schema  = var.event_schema
        }
        runAfter = {}
      }
      Get_Active_Session = {
        type = "Http"
        inputs = {
          method = "GET"
          uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{body('Parse_Event')?['${var.partition_key_field}']}',RowKey='active')"
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
          Parse_Event = ["Succeeded"]
        }
      }
      Check_New_Session = {
        type = "If"
        expression = {
          and = [
            {
              equals = [
                "@outputs('Get_Active_Session')['statusCode']",
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
              body = local.insert_entity_body
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
                recipient = jsondecode(local.teams_notification_recipient)
                messageBody = templatestring(var.notification_message_template, {
                  close_session_url = azapi_resource_action.close_session_callback_url.output.value
                })
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
                uri    = "${local.table_endpoint}/${local.table_name}(PartitionKey='@{body('Parse_Event')?['${var.partition_key_field}']}',RowKey='active')"
                headers = {
                  "Content-Type" = "application/json"
                  Accept         = "application/json;odata=nometadata"
                  "x-ms-version" = "2020-12-06"
                  "If-Match"     = "*"
                }
                body = local.update_entity_body
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
          Get_Active_Session = ["Succeeded", "Failed"]
        }
      }
    }
    runAfter = {}
  })
}

// ── Close Workflow Actions ───────────────────────────────────

resource "azurerm_logic_app_action_custom" "get_active_session" {
  name         = "Get_Active_Session"
  logic_app_id = azurerm_logic_app_workflow.close_session.id

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
  logic_app_id = azurerm_logic_app_workflow.close_session.id

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
      Get_Active_Session = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.get_active_session]
}

resource "azurerm_logic_app_action_custom" "post_closure_summary" {
  name         = "Post_Closure_Summary"
  logic_app_id = azurerm_logic_app_workflow.close_session.id

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
        recipient   = jsondecode(local.teams_notification_recipient)
        messageBody = var.closure_message_template
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
  logic_app_id = azurerm_logic_app_workflow.close_session.id

  body = jsonencode({
    type = "Response"
    kind = "Http"
    inputs = {
      statusCode = "@{if(equals(actions('Delete_Entity')['status'], 'Succeeded'), 200, if(equals(actions('Get_Active_Session')['status'], 'Failed'), 404, 500))}"
      headers = {
        "Content-Type" = "text/plain"
      }
      body = "@{if(equals(actions('Delete_Entity')['status'], 'Succeeded'), '${var.close_success_message}', if(equals(actions('Get_Active_Session')['status'], 'Failed'), '${var.close_not_found_message}', '${var.close_failure_message}'))}"
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

  scope                = local.storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_logic_app_workflow.teams_notification.identity[0].principal_id
}

resource "azurerm_role_assignment" "close_session_storage_table_data_contributor" {
  count = var.should_assign_roles ? 1 : 0

  scope                = local.storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_logic_app_workflow.close_session.identity[0].principal_id
}
