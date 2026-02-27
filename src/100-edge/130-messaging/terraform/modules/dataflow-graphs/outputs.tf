/*
 * Dataflow Graph Outputs
 */

output "dataflow_graphs" {
  description = "Map of dataflow graph resources by name."
  value = {
    for name, graph in azapi_resource.dataflow_graph : name => {
      id   = graph.id
      name = graph.output.name
    }
  }
}
