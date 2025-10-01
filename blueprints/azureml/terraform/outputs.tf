/*
 *  Azure ML Outputs
 */

output "azureml_workspace" {
  description = "The Azure ML workspace object when created or discovered."
  value       = module.cloud_azureml.azureml_workspace
}

output "nat_gateway" {
  description = "The NAT gateway resource used for managed outbound access when networking is created."
  value       = try(module.cloud_networking[0].nat_gateway, null)
}

output "nat_gateway_public_ips" {
  description = "Public IP resources associated with the NAT gateway when managed outbound access is enabled."
  value       = try(module.cloud_networking[0].nat_gateway_public_ips, {})
}

output "azureml_edge_extension" {
  description = "The Azure ML edge extension deployment object when deployed."
  value       = try(module.edge_azureml[0].edge_extension, null)
}

output "key_vault" {
  description = "Key Vault object used for the workspace."
  value = try(module.cloud_security_identity[0].key_vault, {
    id   = try(data.azurerm_key_vault.existing[0].id, null)
    name = try(data.azurerm_key_vault.existing[0].name, null)
  })
}

output "application_insights" {
  description = "Application Insights object used for the workspace."
  value = try(module.cloud_observability[0].application_insights, {
    id                  = try(data.azurerm_application_insights.existing[0].id, null)
    name                = try(data.azurerm_application_insights.existing[0].name, null)
    instrumentation_key = try(data.azurerm_application_insights.existing[0].instrumentation_key, null)
  })
  sensitive = true
}

output "aks_cluster" {
  description = "The AKS cluster object when created or discovered for ML integration."
  value       = try(module.cloud_kubernetes[0].aks, null)
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for the AKS cluster when workload identity is enabled."
  value       = try(module.cloud_kubernetes[0].aks_oidc_issuer_url, null)
}

output "arc_connected_cluster_id" {
  description = "The Arc connected cluster id when created or discovered for edge ML scenarios."
  value       = try(data.azapi_resource.arc_connected_cluster[0].id, null)
}

output "storage_account" {
  description = "Storage Account object used for the workspace."
  value = try(module.cloud_data[0].storage_account, {
    id   = try(data.azurerm_storage_account.existing[0].id, null)
    name = try(data.azurerm_storage_account.existing[0].name, null)
  })
}

/*
 * VPN Gateway Outputs
 */

output "vpn_gateway" {
  description = "VPN Gateway configuration when enabled."
  value       = try(module.cloud_vpn_gateway[0].vpn_gateway, null)
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP address for client configuration."
  value       = try(module.cloud_vpn_gateway[0].vpn_gateway_public_ip, null)
}

output "vpn_client_connection_info" {
  description = "VPN client connection information including download URLs."
  value       = try(module.cloud_vpn_gateway[0].client_connection_info, null)
}

output "private_resolver_dns_ip" {
  description = "Private Resolver DNS IP address for VPN client configuration."
  value       = try(module.cloud_networking[0].dns_server_ip, null)
}
