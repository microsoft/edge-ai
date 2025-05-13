output "event_hub" {
  value = {
    namespace_name    = azurerm_eventhub_namespace.destination_event_hub_namespace.name
    event_hub_name    = azurerm_eventhub.destination_eh.name
    capacity          = azurerm_eventhub_namespace.destination_event_hub_namespace.capacity
    sku               = azurerm_eventhub_namespace.destination_event_hub_namespace.sku
    partition_count   = azurerm_eventhub.destination_eh.partition_count
    message_retention = azurerm_eventhub.destination_eh.message_retention
  }
}
