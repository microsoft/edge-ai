/**
 * Leak Detection Blueprint Outputs
 *
 * Outputs for the leak detection scenario deployment including cloud resources,
 * edge cluster, container registry, and notification pipeline.
 */

/*
 * Azure IoT Operations Outputs
 */

output "azure_iot_operations" {
  description = "Azure IoT Operations deployment details."
  value = {
    custom_location_id = module.edge_iot_ops.custom_locations.id
    instance_name      = module.edge_iot_ops.aio_instance.name
    mqtt_broker        = module.edge_iot_ops.aio_mqtt_broker.brokerListenerHostName
    mqtt_port_no_tls   = var.should_create_anonymous_broker_listener ? tostring(try(module.edge_iot_ops.aio_broker_listener_anonymous.port, "Not configured")) : "Not configured"
    mqtt_port_tls      = module.edge_iot_ops.aio_mqtt_broker.brokerListenerPort
    namespace          = module.edge_iot_ops.aio_namespace
  }
}

output "assets" {
  description = "IoT asset resources."
  value = {
    assets                  = module.edge_assets.assets
    asset_endpoint_profiles = module.edge_assets.asset_endpoint_profiles
  }
}

/*
 * Cluster Connection Outputs
 */

output "cluster_connection" {
  description = "Commands and information to connect to the deployed cluster."
  value = {
    arc_cluster_name           = module.edge_cncf_cluster.connected_cluster_name
    arc_cluster_resource_group = module.edge_cncf_cluster.connected_cluster_resource_group_name
    arc_proxy_command          = module.edge_cncf_cluster.azure_arc_proxy_command
  }
}

/*
 * Container Registry Outputs
 */

output "container_registry" {
  description = "Azure Container Registry resources."
  value       = module.cloud_acr.acr
}

/*
 * Data Storage Outputs
 */

output "data_storage" {
  description = "Data storage resources."
  value = {
    schema_registry_endpoint = try(module.cloud_data.schema_registry.endpoint, "Not deployed")
    schema_registry_name     = try(module.cloud_data.schema_registry.name, "Not deployed")
    storage_account_name     = try(module.cloud_data.storage_account.name, "Not deployed")
  }
}

/*
 * Deployment Summary Outputs
 */

output "deployment_summary" {
  description = "Summary of the deployment configuration."
  value = {
    resource_group = module.cloud_resource_group.resource_group.name
  }
}

/*
 * Messaging Outputs
 */

output "event_grid_topic_endpoint" {
  description = "Event Grid topic endpoint."
  value       = try(module.cloud_messaging.eventgrid.endpoint, "Not deployed")
}

output "event_grid_topic_name" {
  description = "Event Grid topic name."
  value       = try(module.cloud_messaging.eventgrid.topic_name, "Not deployed")
}

output "eventhub_name" {
  description = "Event Hub name."
  value       = try(module.cloud_messaging.eventhubs[0].eventhub_name, "Not deployed")
}

output "eventhub_namespace_name" {
  description = "Event Hub namespace name."
  value       = try(module.cloud_messaging.eventhubs[0].namespace_name, "Not deployed")
}

output "function_app" {
  description = "Azure Function App for alert notifications."
  value       = try(module.cloud_messaging.function_app, null)
}

/*
 * Notification Outputs
 */

output "notification" {
  description = "Alert notification pipeline resources."
  value = {
    logic_app              = try(module.cloud_notification[0].logic_app, null)
    close_logic_app        = try(module.cloud_notification[0].close_logic_app, null)
    close_session_endpoint = try(module.cloud_notification[0].close_session_endpoint, null)
    storage_account        = try(module.cloud_notification[0].storage_account, null)
  }
  sensitive = true
}

/*
 * Networking Outputs
 */

output "nat_gateway" {
  description = "NAT gateway resource when managed outbound access is enabled."
  value       = module.cloud_networking.nat_gateway
}

/*
 * Dataflow Outputs
 */

output "dataflow_graphs" {
  description = "Map of dataflow graph resources by name."
  value       = try(module.edge_messaging.dataflow_graphs, {})
}

output "dataflows" {
  description = "Map of dataflow resources by name."
  value       = try(module.edge_messaging.dataflows, {})
}

output "dataflow_endpoints" {
  description = "Map of dataflow endpoint resources by name."
  value       = try(module.edge_messaging.dataflow_endpoints, {})
}

/*
 * Edge Infrastructure Outputs
 */

output "vm_host" {
  description = "Virtual machine host resources."
  value       = module.cloud_vm_host.virtual_machines
}

output "arc_connected_cluster" {
  description = "Azure Arc connected cluster resources."
  value       = module.edge_cncf_cluster.arc_connected_cluster
}

/*
 * Observability Outputs
 */

output "observability" {
  description = "Monitoring and observability resources."
  sensitive   = true
  value = {
    azure_monitor_workspace_name = try(module.cloud_observability.azure_monitor_workspace.name, "Not deployed")
    grafana_endpoint             = try(module.cloud_observability.azure_managed_grafana.endpoint, "Not deployed")
    grafana_name                 = try(module.cloud_observability.azure_managed_grafana.name, "Not deployed")
    log_analytics_workspace_name = try(module.cloud_observability.log_analytics_workspace.name, "Not deployed")
  }
}
