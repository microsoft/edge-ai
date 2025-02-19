output "connected_cluster_name" {
  value = local.arc_resource_name
}

output "connected_cluster_resource_group_name" {
  value = var.aio_resource_group.name
}

output "azure_arc_proxy_command" {
  value = "az connectedk8s proxy -n ${local.arc_resource_name} -g ${var.aio_resource_group.name}"
}

output "arc_connected_cluster" {
  value = try(data.azapi_resource.arc_connected_cluster[0].output, null)
}
