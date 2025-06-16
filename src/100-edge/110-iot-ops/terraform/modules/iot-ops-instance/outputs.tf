output "instance_name" {
  value = local.aio_instance_name
}

output "custom_location_id" {
  value = azapi_resource.custom_location.id
}

output "custom_locations" {
  value = {
    id   = azapi_resource.custom_location.id
    name = azapi_resource.custom_location.name
  }
}

output "aio_instance" {
  value = {
    id   = azapi_resource.instance.id
    name = azapi_resource.instance.name
  }
}

output "aio_dataflow_profile" {
  value = {
    id   = azapi_resource.data_profiles.id
    name = azapi_resource.data_profiles.name
  }
}
