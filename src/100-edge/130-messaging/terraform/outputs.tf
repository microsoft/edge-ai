/*
 * Edge Messaging Outputs
 */

output "event_hub_dataflow" {
  description = "The Event Hub dataflow details."
  value       = try(module.sample_eventhub_dataflow[0], null)
}

output "event_grid_dataflow" {
  description = "The Event Grid dataflow details."
  value       = try(module.sample_eventgrid_dataflow[0], null)
}

output "fabric_rti_dataflow" {
  description = "The Fabric RTI dataflow details."
  value       = try(module.sample_fabric_rti_dataflow[0], null)
}

output "dataflow_graphs" {
  description = "Map of dataflow graph resources by name."
  value       = try(module.dataflow_graphs[0].dataflow_graphs, {})
}
