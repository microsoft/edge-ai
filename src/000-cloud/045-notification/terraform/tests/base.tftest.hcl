provider "azurerm" {
  storage_use_azuread = true
  features {}
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group

    eventhub_namespace = run.setup_tests.eventhub_namespace
    eventhub_name      = "evh-test"
    storage_account    = run.setup_tests.storage_account
    teams_recipient_id = "19:test-thread@thread.v2"

    event_schema = {
      type = "object"
      properties = {
        device_id = { type = "string" }
      }
    }

    partition_key_field = "device_id"

    notification_message_template = "<p>Alert: @{body('Parse_Event')?['device_id']}</p><p><a href=\"$${close_session_url}\">Close</a></p>"
    closure_message_template      = "<p>Closed</p>"
  }

  assert {
    condition     = azurerm_logic_app_workflow.teams_notification.name != ""
    error_message = "Notification Logic App should be created"
  }

  assert {
    condition     = azurerm_logic_app_workflow.close_session.name != ""
    error_message = "Close session Logic App should be created"
  }

  assert {
    condition     = length(azurerm_role_assignment.eventhub_data_receiver) == 1
    error_message = "Role assignments should be created by default"
  }
}

run "skip_role_assignments" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group

    eventhub_namespace = run.setup_tests.eventhub_namespace
    eventhub_name      = "evh-test"
    storage_account    = run.setup_tests.storage_account
    teams_recipient_id = "19:test-thread@thread.v2"

    event_schema = {
      type = "object"
      properties = {
        device_id = { type = "string" }
      }
    }

    partition_key_field = "device_id"

    notification_message_template = "<p>Alert</p>"
    closure_message_template      = "<p>Closed</p>"

    should_assign_roles = false
  }

  assert {
    condition     = length(azurerm_role_assignment.eventhub_data_receiver) == 0
    error_message = "Role assignments should not be created when should_assign_roles is false"
  }
}

run "verify_default_naming" {
  command = plan

  variables {
    resource_prefix = "testpre"
    environment     = "test"
    location        = run.setup_tests.location
    instance        = "001"
    resource_group  = run.setup_tests.resource_group

    eventhub_namespace = run.setup_tests.eventhub_namespace
    eventhub_name      = "evh-test"
    storage_account    = run.setup_tests.storage_account
    teams_recipient_id = "19:test-thread@thread.v2"

    event_schema = {
      type = "object"
      properties = {
        device_id = { type = "string" }
      }
    }

    partition_key_field = "device_id"

    notification_message_template = "<p>Alert</p>"
    closure_message_template      = "<p>Closed</p>"

    insert_entity_body = {
      PartitionKey = "@{body('Parse_Event')?['device_id']}"
      RowKey       = "active"
      CustomField  = "custom-value"
    }

    update_entity_body = {
      LastEventAt = "@{utcNow()}"
      CustomField = "updated-value"
    }
  }

  assert {
    condition     = azurerm_logic_app_workflow.teams_notification.name == "la-testpre-notify-test-001"
    error_message = "Notification Logic App should follow naming pattern 'la-{prefix}-{notification_purpose}-{env}-{instance}'"
  }

  assert {
    condition     = azurerm_logic_app_workflow.close_session.name == "la-testpre-close-test-001"
    error_message = "Close Logic App should follow naming pattern 'la-{prefix}-{close_purpose}-{env}-{instance}'"
  }
}
