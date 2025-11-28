/*
 * Akri Connector Template Outputs
 */

output "connector_templates" {
  description = "Map of deployed connector templates by name with id and type."
  value = {
    for name, template in azapi_resource.connector_template : name => {
      id   = template.id
      name = template.name
      type = local.processed_connectors[name].type
    }
  }
}

output "connector_template_ids" {
  description = "Map of connector template IDs by name."
  value = {
    for name, template in azapi_resource.connector_template :
    name => template.id
  }
}

output "connector_types_deployed" {
  description = "List of connector types that were deployed."
  value       = distinct([for conn in local.processed_connectors : conn.type])
}
