output "eventgrid" {
  description = "Event Grid configuration including topic name and endpoint"
  value       = try(module.eventgrid[0].eventgrid, null)
}

output "eventhub_namespace" {
  description = "Event Hub namespace configuration"
  value       = try(module.eventhub[0].eventhub_namespace, null)
}

output "eventhubs" {
  description = "Event Hub(s) configuration"
  value       = try(module.eventhub[0].eventhubs, null)
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
