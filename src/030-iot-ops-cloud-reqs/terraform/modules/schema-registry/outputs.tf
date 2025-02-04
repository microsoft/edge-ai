output "registry_id" {
  value = azapi_resource.schema_registry.output.id
}

output "adr_schema_registry" {
  value = azapi_resource.schema_registry.output
}
