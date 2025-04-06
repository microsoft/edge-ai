output "event_grid" {
  description = "Event Grid configuration including topic name and endpoint"
  value       = try(module.event_grid[0].event_grid, null)
}

output "event_grid_endpoint" {
  description = "The Event Grid endpoint URL for MQTT connections"
  value       = try(module.event_grid[0].event_grid.endpoint, null)
}

output "event_hub" {
  description = "Event Hub configuration including connection string and endpoint"
  value       = try(module.event_hubs[0].event_hub, null)
}
