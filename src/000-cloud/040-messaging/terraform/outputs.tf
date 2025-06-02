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

/*
 * Azure Functions Outputs
 */

output "app_service_plan" {
  description = "App Service Plan configuration and details."
  value       = try(module.app_service_plan[0].app_service_plan, null)
}

output "function_app" {
  description = "Function App configuration and details."
  value       = try(module.azure_functions[0].function_app, null)
}

output "function_storage_account" {
  description = "Storage Account used by the Function App."
  value       = try(module.azure_functions[0].storage_account, null)
  sensitive   = true
}
