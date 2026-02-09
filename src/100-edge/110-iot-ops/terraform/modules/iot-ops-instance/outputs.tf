/*
 * Instance Outputs
 */

output "aio_dataflow_profile" {
  description = "Azure IoT Operations dataflow profile details."
  value = {
    id   = azapi_resource.data_profiles.id
    name = azapi_resource.data_profiles.name
  }
}

output "aio_instance" {
  description = "Azure IoT Operations instance details."
  value = {
    id   = azapi_resource.instance.id
    name = azapi_resource.instance.name
  }
}

output "aio_namespace" {
  description = "Azure IoT Operations namespace."
  value       = azurerm_arc_kubernetes_cluster_extension.iot_operations.release_namespace
}

/*
 * Custom Location Outputs
 */

output "custom_locations" {
  description = "Custom location details."
  value = {
    id   = azapi_resource.custom_location.id
    name = azapi_resource.custom_location.name
  }
}

/*
 * Extension Identity Outputs
 */

output "extension_identity" {
  description = "AIO Arc extension identity information for role assignments."
  value = {
    principal_id = azurerm_arc_kubernetes_cluster_extension.iot_operations.identity[0].principal_id
  }
}

/*
 * MQTT Broker Outputs
 */

output "aio_broker_listener_anonymous" {
  description = "Anonymous MQTT Broker Listener configuration details."
  value = var.should_create_anonymous_broker_listener ? {
    serviceName = try(azapi_resource.broker_listener_anonymous[0].body.properties.serviceName, null)
    port        = try(azapi_resource.broker_listener_anonymous[0].body.properties.ports[0].port, null)
  } : null
}

output "aio_mqtt_broker" {
  description = "MQTT Broker configuration details."
  value = {
    brokerListenerHostName = local.mqtt_broker_hostname
    brokerListenerPort     = azapi_resource.broker_listener.body.properties.ports[0].port
  }
}
