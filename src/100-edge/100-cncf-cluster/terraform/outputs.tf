/*
 * Arc Connected Cluster Outputs
 */

output "connected_cluster_name" {
  description = "The name of the Arc connected cluster."
  value       = local.arc_resource_name
}

output "connected_cluster_resource_group_name" {
  description = "The name of the resource group containing the Arc connected cluster."
  value       = var.resource_group.name
}

output "azure_arc_proxy_command" {
  description = "The AZ CLI command to Arc Connect Proxy to the cluster."
  value       = "az connectedk8s proxy -n ${local.arc_resource_name} -g ${var.resource_group.name}"
}

output "arc_connected_cluster" {
  description = "The Arc resource for the connected cluster."
  value       = try(data.azapi_resource.arc_connected_cluster[0].output, null)
}

/*
 * Cluster Authentication Outputs
 */

output "server_token" {
  description = "The token used by the server in the k3s cluster. ('null' if the server is responsible for generating the token)"
  value       = module.ubuntu_k3s.cluster_server_token
  sensitive   = true
}

/*
 * Key Vault Secret Outputs
 */

output "server_script_secret_name" {
  description = "The name of the key vault secret containing the server script."
  value       = module.ubuntu_k3s.server_script_secret_name
}

output "node_script_secret_name" {
  description = "The name of the key vault secret containing the node script."
  value       = module.ubuntu_k3s.node_script_secret_name
}

output "server_script_secret_download_command" {
  description = "Az CLI command to download the server script secret."
  value       = module.ubuntu_k3s.server_script_secret_download_command
}

output "node_script_secret_download_command" {
  description = "Az CLI command to download the node script secret."
  value       = module.ubuntu_k3s.node_script_secret_download_command
}
