output "event_grid" {
  description = "Event Grid configuration including topic name and endpoint"
  value       = module.event_grid.event_grid
}

output "event_grid_endpoint" {
  description = "The Event Grid endpoint URL for MQTT connections"
  value       = module.event_grid.event_grid.endpoint
}

output "event_hub" {
  description = "Event Hub configuration including connection string and endpoint"
  value       = module.event_hubs.event_hub
}