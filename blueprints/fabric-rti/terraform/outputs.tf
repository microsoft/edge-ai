/*
 * Fabric RTI Component Outputs
 */

output "fabric_eventstream" {
  description = "The Microsoft Fabric EventStream with custom endpoint for AIO integration."
  value       = module.fabric_rti.eventstream
}

output "fabric_rti_custom_endpoint_source_connections" {
  description = "The Fabric RTI connection details."
  value       = module.fabric_rti.custom_endpoint_source_connections
}

output "eventstream_dag_configuration" {
  description = "The DAG configuration used for EventStream creation."
  value       = module.fabric_rti.eventstream_dag_configuration
}

/*
 * Edge Messaging Component Outputs
 */

output "fabric_rti_dataflow" {
  description = "The Fabric RTI dataflow endpoint for data ingestion."
  value       = module.edge_messaging.fabric_rti_dataflow
}

/*
 * Referenced Infrastructure Outputs
 */

output "resource_group" {
  description = "The existing resource group containing all resources."
  value       = data.azurerm_resource_group.existing
}

output "fabric_workspace" {
  description = "The existing Microsoft Fabric workspace for RTI analytics."
  value       = data.fabric_workspace.existing
}

output "fabric_eventhouse" {
  description = "The existing Microsoft Fabric Eventhouse for real-time analytics."
  value       = data.fabric_eventhouse.existing
}

output "aio_instance" {
  description = "The existing Azure IoT Operations instance."
  value       = data.azapi_resource.aio_instance.output
}

output "aio_custom_location" {
  description = "The existing custom location for Azure IoT Operations."
  value       = data.azapi_resource.custom_location.output
}
