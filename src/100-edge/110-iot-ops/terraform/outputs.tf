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
