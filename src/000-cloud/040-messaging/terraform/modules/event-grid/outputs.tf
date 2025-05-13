output "event_grid" {
  value = {
    topic_name                   = var.topic_name
    endpoint                     = "${azurerm_eventgrid_namespace.aio_eg_ns.name}.${var.location}-1.ts.eventgrid.azure.net:8883"
    capacity                     = azurerm_eventgrid_namespace.aio_eg_ns.capacity
    sku                          = azurerm_eventgrid_namespace.aio_eg_ns.sku
    max_client_sessions_per_auth = azurerm_eventgrid_namespace.aio_eg_ns.topic_spaces_configuration[0].maximum_client_sessions_per_authentication_name
    namespace_name               = azurerm_eventgrid_namespace.aio_eg_ns.name
    topic_space_name             = azapi_resource.event_grid_namespace_topic_space.name
  }
}
