output "event_hub" {
  value = {
    namespace_name = azurerm_eventhub_namespace.destination_event_hub_namespace.name
    event_hub_name = azurerm_eventhub.destination_eh.name
  }
}
