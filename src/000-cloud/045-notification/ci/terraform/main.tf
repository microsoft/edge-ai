/**
 * # Notification CI
 *
 * Minimal deployment configuration for CI testing of the notification component.
 */

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name     = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    eventhub_namespace_name = "evhns-${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "main" {
  name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source = "../../terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = data.azurerm_resource_group.main.location

  resource_group = data.azurerm_resource_group.main

  eventhub_namespace = {
    id   = "${data.azurerm_resource_group.main.id}/providers/Microsoft.EventHub/namespaces/${terraform_data.defer.output.eventhub_namespace_name}"
    name = terraform_data.defer.output.eventhub_namespace_name
  }

  eventhub_name = var.eventhub_name
  storage_account = {
    id   = "${data.azurerm_resource_group.main.id}/providers/Microsoft.Storage/storageAccounts/st${replace(var.resource_prefix, "-", "")}${var.environment}${var.instance}"
    name = "st${replace(var.resource_prefix, "-", "")}${var.environment}${var.instance}"
  }

  teams_recipient_id = var.teams_recipient_id

  event_schema = {
    type = "object"
    properties = {
      event_type = { type = "string" }
      timestamp  = { type = "number" }
      device_id  = { type = "string" }
    }
  }

  partition_key_field = "device_id"

  notification_message_template = "<p><strong>Event Alert</strong></p><p>Device: @{body('Parse_Event')?['device_id']}</p><p><a href=\"$${close_session_url}\">Close</a></p>"

  closure_message_template = "<p><strong>Session Closed</strong></p><p>Device: @{triggerOutputs()['queries']['device']}</p>"

  should_assign_roles = false
}
