/*
 * Registry Endpoint Outputs
 */

output "mcr_endpoint" {
  description = "Default MCR registry endpoint"
  value = {
    id   = azapi_resource.registry_endpoint_mcr.id
    name = azapi_resource.registry_endpoint_mcr.name
    host = "mcr.microsoft.com"
  }
}

output "custom_endpoints" {
  description = "Map of custom registry endpoints by name"
  value = {
    for name, ep in azapi_resource.registry_endpoint : name => {
      id   = ep.id
      name = ep.name
      host = var.registry_endpoints[index(var.registry_endpoints[*].name, name)].host
    }
  }
}

output "acr_role_assignments" {
  description = "Map of ACR role assignment IDs by endpoint name"
  value = {
    for name, ra in azurerm_role_assignment.registry_acr_pull :
    name => ra.id
  }
}
