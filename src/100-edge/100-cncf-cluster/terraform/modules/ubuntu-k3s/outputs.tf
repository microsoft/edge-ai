output "cluster_server_token" {
  description = "The token used by the server in the cluster for node authentication. ('null' if the server is responsible for generating the token)"
  value       = try(random_string.cluster_server_token[0].result, var.cluster_server_token)

  sensitive = true
}

output "server_script_secret_name" {
  description = "The name of the key vault secret containing the server script."
  value       = var.should_upload_to_key_vault && var.key_vault != null ? var.server_script_secret_name : null
}

output "node_script_secret_name" {
  description = "The name of the key vault secret containing the node script."
  value       = var.should_upload_to_key_vault && var.key_vault != null ? var.node_script_secret_name : null
}

output "server_script_secret_download_command" {
  description = "Az CLI command to download the server script secret."
  value       = var.should_upload_to_key_vault && var.key_vault != null ? "az keyvault secret show --vault-name ${var.key_vault.name} --name ${var.server_script_secret_name} --query value -o tsv > ./cluster-server-setup.sh && chmod +x ./cluster-server-setup.sh" : null
}

output "node_script_secret_download_command" {
  description = "Az CLI command to download the node script secret."
  value       = var.should_upload_to_key_vault && var.key_vault != null ? "az keyvault secret show --vault-name ${var.key_vault.name} --name ${var.node_script_secret_name} --query value -o tsv > ./cluster-node-setup.sh && chmod +x ./cluster-node-setup.sh" : null
}
