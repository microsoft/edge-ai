output "connected_cluster_name" {
  value = local.arc_resource_name
}

output "connected_cluster_resource_group_name" {
  value = terraform_data.defer.output.resource_group_name
}

output "azure_arc_proxy_command" {
  value = "az connectedk8s proxy -n ${local.arc_resource_name} -g ${terraform_data.defer.output.resource_group_name}"
}
