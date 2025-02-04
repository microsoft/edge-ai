output "instance_name" {
  value = local.aio_instance_name
}

output "custom_location_id" {
  value = azapi_resource.custom_location.output.id
}

output "custom_locations" {
  value = azapi_resource.custom_location.output
}

output "aio_instance" {
  value = azapi_resource.instance.output
}

output "aio_dataflow_profile" {
  value = azapi_resource.data_profiles.output
}
