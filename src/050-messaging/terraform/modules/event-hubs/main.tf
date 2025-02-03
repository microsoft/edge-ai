/**
 * # Azure Event Hubs
 *
 * Create a new Event Hub namespace and Event Hub and assign the AIO instance UAMI the Azure Event Hubs Data Sender role.
 */

resource "azurerm_eventhub_namespace" "destination_event_hub_namespace" {
  name                = "evhns-${var.resource_prefix}-aio"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard" # Basic is not supported for Kafka protocol required for dataflows
  capacity            = var.capacity
}

resource "azurerm_eventhub" "destination_eh" {
  name              = "evh-${var.resource_prefix}-aio"
  namespace_id      = azurerm_eventhub_namespace.destination_event_hub_namespace.id
  partition_count   = var.partition_count
  message_retention = var.message_retention
}

resource "azurerm_role_assignment" "data_sender" {
  scope                = azurerm_eventhub_namespace.destination_event_hub_namespace.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = var.aio_uami_principal_id
}
