/*
 * Akri REST HTTP Connector Outputs
 */

output "connector_template" {
  description = "The deployed REST HTTP connector template."
  value = {
    id   = azapi_resource.connector_template.id
    name = azapi_resource.connector_template.name
  }
}

output "connector_template_id" {
  description = "ID of the deployed REST HTTP connector template."
  value       = azapi_resource.connector_template.id
}

output "connector_template_name" {
  description = "Name of the deployed REST HTTP connector template."
  value       = azapi_resource.connector_template.name
}
