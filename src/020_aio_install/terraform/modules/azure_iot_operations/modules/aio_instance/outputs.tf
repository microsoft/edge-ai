output "instance_name" {
  value = local.aio_instance_name
}

output "custom_location_id" {
  value = azapi_resource.custom_location.output.id
}

output "aio_extension_name" {
  value = azurerm_arc_kubernetes_cluster_extension.iot_operations.name
}
