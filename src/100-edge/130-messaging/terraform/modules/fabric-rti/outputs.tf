output "fabric_rti_endpoint" {
  description = "The Fabric RTI dataflow endpoint."
  value = {
    id   = azapi_resource.fabric_rti_endpoint.id
    name = azapi_resource.fabric_rti_endpoint.name
  }
}

output "fabric_rti_dataflow" {
  description = "The Fabric RTI dataflow."
  value = {
    id   = azapi_resource.fabric_rti_dataflow.id
    name = azapi_resource.fabric_rti_dataflow.name
  }
}
