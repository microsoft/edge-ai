/*
 * Dataflow Endpoint Outputs
 */

output "dataflow_endpoints" {
  description = "Map of dataflow endpoint resources by name."
  value = {
    for name, ep in azapi_resource.dataflow_endpoint : name => {
      id   = ep.id
      name = ep.output.name
    }
  }
}
