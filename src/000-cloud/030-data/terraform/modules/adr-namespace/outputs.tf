output "adr_namespace" {
  description = "The complete ADR namespace resource information."
  value = {
    id   = azapi_resource.adr_namespace.id
    name = azapi_resource.adr_namespace.name
  }
}
