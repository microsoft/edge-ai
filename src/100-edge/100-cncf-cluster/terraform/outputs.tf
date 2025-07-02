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
  value       = try(module.ubuntu_k3s[0].cluster_server_token, null)
  sensitive   = true
}

/*
 * Key Vault Secret Outputs
 */

output "server_script_secret_name" {
  description = "The name of the key vault secret containing the server script."
  value       = try(module.ubuntu_k3s[0].server_script_secret_name, null)
}

output "node_script_secret_name" {
  description = "The name of the key vault secret containing the node script."
  value       = try(module.ubuntu_k3s[0].node_script_secret_name, null)
}

output "server_script_secret_download_command" {
  description = "Az CLI command to download the server script secret."
  value       = try(module.ubuntu_k3s[0].server_script_secret_download_command, null)
}

output "node_script_secret_download_command" {
  description = "Az CLI command to download the node script secret."
  value       = try(module.ubuntu_k3s[0].node_script_secret_download_command, null)
}
