/*
 * AIO Instance Outputs
 */

output "aio_dataflow_profile" {
  description = "The AIO dataflow profile."
  value       = module.iot_ops_instance.aio_dataflow_profile
}

output "aio_instance" {
  description = "The AIO instance."
  value       = module.iot_ops_instance.aio_instance
}

output "aio_instance_name" {
  description = "The name of the AIO instance."
  value       = module.iot_ops_instance.instance_name
}

/*
 * Custom Location Outputs
 */

output "custom_location_id" {
  description = "The ID of the custom location."
  value       = module.iot_ops_instance.custom_location_id
}

output "custom_locations" {
  description = "The custom locations."
  value       = module.iot_ops_instance.custom_locations
}
