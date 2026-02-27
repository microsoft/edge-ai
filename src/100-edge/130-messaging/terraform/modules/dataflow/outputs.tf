/*
 * Dataflow Outputs
 */

output "dataflows" {
  description = "Map of dataflow resources by name."
  value = {
    for name, df in azapi_resource.dataflow : name => {
      id   = df.id
      name = df.output.name
    }
  }
}
