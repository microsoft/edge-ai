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
 * Akri REST HTTP Connector Outputs
 */

output "akri_rest_connector" {
  description = "The Akri REST HTTP connector template details"
  value       = var.should_enable_akri_rest_connector ? module.akri_rest_connector[0].connector_template : null
}

output "akri_rest_connector_template_id" {
  description = "The ID of the Akri REST HTTP Connector template"
  value       = var.should_enable_akri_rest_connector ? module.akri_rest_connector[0].connector_template_id : null
}

output "akri_rest_connector_template_name" {
  description = "The name of the Akri REST HTTP Connector template"
  value       = var.should_enable_akri_rest_connector ? module.akri_rest_connector[0].connector_template_name : null
}
