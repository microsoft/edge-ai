/*
 * AIO Instance Outputs
 */

output "aio_dataflow_profile" {
  description = "The Azure IoT Operations dataflow profile."
  value       = module.iot_ops_instance.aio_dataflow_profile
}

output "aio_instance" {
  description = "The Azure IoT Operations instance."
  value       = module.iot_ops_instance.aio_instance
}

output "aio_namespace" {
  description = "The Azure IoT Operations namespace."
  value       = module.iot_ops_instance.aio_namespace
}

/*
 * Custom Location Outputs
 */
output "custom_locations" {
  description = "The custom location details."
  value       = module.iot_ops_instance.custom_locations
}

/*
 * MQTT Broker Outputs
 */

output "aio_broker_listener_anonymous" {
  description = "The anonymous MQTT Broker Listener configuration details."
  value       = module.iot_ops_instance.aio_broker_listener_anonymous
}

output "aio_mqtt_broker" {
  description = "The MQTT Broker configuration details."
  value       = module.iot_ops_instance.aio_mqtt_broker
}

/*
 * Akri Connectors Outputs
 */

output "akri_connector_templates" {
  description = "Map of deployed Akri connector templates by name with id and type. Returns null if no connectors are deployed."
  value = anytrue([
    var.should_enable_akri_rest_connector,
    var.should_enable_akri_media_connector,
    var.should_enable_akri_onvif_connector,
    var.should_enable_akri_sse_connector,
    length(var.custom_akri_connectors) > 0
  ]) ? module.akri_connectors[0].connector_templates : null
}

/*
 * Registry Endpoints Outputs
 */

output "registry_endpoint_mcr" {
  description = "The default MCR registry endpoint."
  value       = module.registry_endpoints.mcr_endpoint
}

output "registry_endpoints_custom" {
  description = "Map of custom registry endpoints by name with id, name, and host."
  value       = module.registry_endpoints.custom_endpoints
}

output "registry_endpoints_acr_role_assignments" {
  description = "Map of ACR role assignments by endpoint name."
  value       = module.registry_endpoints.acr_role_assignments
}
