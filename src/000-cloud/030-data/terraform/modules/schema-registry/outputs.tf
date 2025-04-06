output "schema_registry" {
  value = {
    id   = azapi_resource.schema_registry.output.id
    name = azapi_resource.schema_registry.output.name
  }
}
