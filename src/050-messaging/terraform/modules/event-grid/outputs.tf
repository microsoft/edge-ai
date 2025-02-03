output "event_grid" {
  value = {
    topic_name = var.topic_name
    endpoint   = "${azurerm_eventgrid_namespace.aio_eg_ns.name}.${var.location}-1.ts.eventgrid.azure.net:8883"
  }
}
