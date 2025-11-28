/**
 * Azure Local IoT Operations Blueprint Outputs
 */

/*
 * Azure IoT Operations Outputs
 */

output "azure_iot_operations" {
  description = "Azure IoT Operations deployment details"
  value = {
    custom_location_id = module.edge_iot_ops.custom_locations.id
    namespace          = module.edge_iot_ops.aio_namespace
    instance_name      = module.edge_iot_ops.aio_instance.name
    mqtt_broker_host   = module.edge_iot_ops.aio_mqtt_broker.brokerListenerHostName
    mqtt_port_tls      = module.edge_iot_ops.aio_mqtt_broker.brokerListenerPort
    mqtt_port_no_tls   = try(module.edge_iot_ops.aio_broker_listener_anonymous.port, null)
  }
}

/*
 * Edge Cluster Outputs
 */

output "arc_connected_cluster" {
  description = "Arc connected cluster resource object"
  value       = module.azure_local_host
}

output "cluster_connection" {
  description = "Commands and identifiers for Arc connected cluster"
  value = {
    arc_cluster_name           = module.azure_local_host.name
    arc_cluster_resource_group = local.use_separate_arc_rg ? module.arc_cluster_resource_group[0].resource_group.name : module.cloud_resource_group.resource_group.name
    arc_proxy_command          = "az connectedk8s proxy -n ${module.azure_local_host.name} -g ${local.use_separate_arc_rg ? module.arc_cluster_resource_group[0].resource_group.name : module.cloud_resource_group.resource_group.name}"
  }
}

/*
 * Cloud Resource Outputs
 */

output "resource_group" {
  description = "Resource group used for the blueprint"
  value       = module.cloud_resource_group.resource_group
}

output "storage" {
  description = "Storage account information"
  value = {
    storage_account = module.cloud_data.storage_account
    schema_registry = module.cloud_data.schema_registry
  }
}

output "messaging" {
  description = "Messaging resources for cloud to edge connectivity"
  value = {
    eventgrid = module.cloud_messaging.eventgrid
    eventhub  = try(module.cloud_messaging.eventhubs[0], null)
  }
}

output "observability" {
  description = "Observability resources"
  sensitive   = true
  value = try({
    grafana_endpoint             = module.cloud_observability.azure_managed_grafana.endpoint
    log_analytics_workspace_name = module.cloud_observability.log_analytics_workspace.name
  }, null)
}

/*
 * Edge Asset Outputs
 */

output "assets" {
  description = "Azure IoT Operations asset definitions"
  value       = try(module.edge_assets[0].assets, [])
}
