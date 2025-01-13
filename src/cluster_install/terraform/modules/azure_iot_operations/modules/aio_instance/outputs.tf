output "instance_name" {
  value = local.aio_instance_name
}

output "custom_location_id" {
  value = azapi_resource.custom_location.output.id
}
