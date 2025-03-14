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

output "server_token" {
  description = "The token used by the server in the k3s cluster. ('null' if the server is responsible for generating the token)"
  value       = module.ubuntu_k3s.cluster_server_token

  sensitive = true
}
