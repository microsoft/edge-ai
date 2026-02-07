/**
 * # Azure Event Hubs
 *
 * Create a new Event Hub namespace and Event Hub and assign the AIO instance UAMI the Azure Event Hubs Data Sender role.
 */

resource "azurerm_eventhub_namespace" "destination_eventhub_namespace" {
  name                = "evhns-${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku      = "Standard"
  capacity = var.capacity

  local_authentication_enabled = false
}

resource "azurerm_eventhub" "destination_eh" {
  for_each          = var.eventhubs
  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.destination_eventhub_namespace.id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
}

resource "azurerm_eventhub_consumer_group" "destination_eh_cg" {
  for_each = {
    for item in flatten([
      for eh_key, eh in var.eventhubs : [
        for cg_key, cg in eh.consumer_groups : {
          eh_name       = eh_key
          cg_name       = cg_key
          user_metadata = cg.user_metadata
        }
      ]
    ])
    : item.cg_name => item
  }

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.destination_eventhub_namespace.name
  eventhub_name       = each.value.eh_name
  resource_group_name = var.resource_group_name
  user_metadata       = each.value.user_metadata
  depends_on          = [azurerm_eventhub.destination_eh]
}

resource "azurerm_role_assignment" "data_sender" {
  scope                = azurerm_eventhub_namespace.destination_eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = var.aio_uami_principal_id
}
