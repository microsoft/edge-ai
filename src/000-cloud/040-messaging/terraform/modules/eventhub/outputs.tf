output "eventhub_namespace" {
  description = "Event Hub namespace values."
  value = {
    name     = azurerm_eventhub_namespace.destination_eventhub_namespace.name
    capacity = azurerm_eventhub_namespace.destination_eventhub_namespace.capacity
    sku      = azurerm_eventhub_namespace.destination_eventhub_namespace.sku
    id       = azurerm_eventhub_namespace.destination_eventhub_namespace.id
  }
}

output "eventhubs" {
  description = "Event Hub values."
  value = [
    for eh in values(azurerm_eventhub.destination_eh) : {
      namespace_name    = azurerm_eventhub_namespace.destination_eventhub_namespace.name
      eventhub_name     = eh.name
      message_retention = eh.message_retention
      partition_count   = eh.partition_count
      consumer_groups = [
        for cg in values(azurerm_eventhub_consumer_group.destination_eh_cg) : {
          name          = cg.name
          user_metadata = cg.user_metadata
        } if cg.eventhub_name == eh.name
      ]
    }
  ]
}
