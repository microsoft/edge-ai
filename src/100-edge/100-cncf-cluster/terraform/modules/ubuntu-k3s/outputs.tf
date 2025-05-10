output "cluster_server_token" {
  description = "The token used by the server in the cluster for node authentication. ('null' if the server is responsible for generating the token)"
  value       = try(random_string.cluster_server_token[0].result, var.cluster_server_token)

  sensitive = true
}

output "server_script_secret_name" {
  description = "The name of the secret for the cluster server script."
  value       = try(azurerm_key_vault_secret.server_script[0].name, null)
}

output "node_script_secret_name" {
  description = "The name of the secret for the cluster node script."
  value       = try(azurerm_key_vault_secret.node_script[0].name, null)
}

output "server_script_secret_download_command" {
  description = "Az CLI command to download the server script secret."
  value       = try("az keyvault secret show --vault-name ${var.key_vault.name} --name ${azurerm_key_vault_secret.server_script[0].name} --query value -o tsv > ./cluster-server-setup.sh && chmod +x ./cluster-server-setup.sh", null)
}

output "node_script_secret_download_command" {
  description = "Az CLI command to download the node script secret."
  value       = try("az keyvault secret show --vault-name ${var.key_vault.name} --name ${azurerm_key_vault_secret.node_script[0].name} --query value -o tsv > ./cluster-node-setup.sh && chmod +x ./cluster-node-setup.sh", null)
}

/*
 * Script Content Outputs
 */

output "server_script_content" {
  description = "The content of the server setup script."
  value       = var.should_use_script_from_secrets_for_deploy ? null : local.script_server_rendered
  sensitive   = true
}

output "node_script_content" {
  description = "The content of the node setup script."
  value       = var.should_use_script_from_secrets_for_deploy ? null : local.script_node_rendered
  sensitive   = true
}
