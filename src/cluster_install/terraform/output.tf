output "public_ssh" {
  value = module.edge_device.public_ssh
}

output "azure_arc_proxy_command" {
  value = "az connectedk8s proxy -n ${module.edge_device.connected_cluster_name} -g ${local.resource_group_name}"
}

output "public_ip" {
  value = module.edge_device.public_ip
}
