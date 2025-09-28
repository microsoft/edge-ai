output "registry" {
  description = "AzureML Registry resource information"
  value = {
    id   = azapi_resource.machine_learning_registry.id
    name = azapi_resource.machine_learning_registry.name
  }
}

output "registry_discovery_url" {
  description = "Registry discovery URL for client configuration"
  value       = try(jsondecode(azapi_resource.machine_learning_registry.output).properties.discoveryUrl, null)
}

output "private_endpoint" {
  description = "Registry private endpoint information"
  value = var.should_enable_private_endpoint ? {
    id         = azurerm_private_endpoint.registry_pe[0].id
    private_ip = azurerm_private_endpoint.registry_pe[0].private_service_connection[0].private_ip_address
  } : null
}
