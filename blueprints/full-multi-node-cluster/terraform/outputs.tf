/*
 * Full Multi Node Cluster Blueprint Outputs
 */

/*
 * Cluster Connection Outputs
 */

output "cluster_connection" {
  description = "Commands and information to connect to the deployed cluster."
  value = {
    arc_cluster_name           = module.edge_cncf_cluster.connected_cluster_name
    arc_cluster_resource_group = module.edge_cncf_cluster.connected_cluster_resource_group_name
    arc_proxy_command          = module.edge_cncf_cluster.azure_arc_proxy_command
  }
}

/*
 * Container Registry Outputs
 */

output "acr_network_posture" {
  description = "Azure Container Registry network posture metadata."
  value       = module.cloud_acr.acr_network_posture
}

output "container_registry" {
  description = "Azure Container Registry resources."
  value       = module.cloud_acr.acr
}

/*
 * PostgreSQL Outputs
 */

output "postgresql_connection_info" {
  description = "PostgreSQL connection information."
  sensitive   = true
  value       = try(module.cloud_postgresql[0].connection_info, null)
}

output "postgresql_databases" {
  description = "Map of PostgreSQL databases."
  value       = try(module.cloud_postgresql[0].databases, null)
}

output "postgresql_server" {
  description = "PostgreSQL Flexible Server object."
  value       = try(module.cloud_postgresql[0].postgresql_server, null)
}

/*
 * Azure Managed Redis Outputs
 */

output "managed_redis" {
  description = "Azure Managed Redis cache object."
  value       = try(module.cloud_managed_redis[0].managed_redis, null)
}

output "managed_redis_connection_info" {
  description = "Azure Managed Redis connection information."
  sensitive   = true
  value       = try(module.cloud_managed_redis[0].connection_info, null)
}

/*
 * AI Foundry Outputs
 */

output "ai_foundry" {
  description = "Azure AI Foundry account resources."
  value       = try(module.cloud_ai_foundry[0].ai_foundry, null)
}

output "ai_foundry_projects" {
  description = "Azure AI Foundry project resources."
  value       = try(module.cloud_ai_foundry[0].projects, null)
}

output "ai_foundry_deployments" {
  description = "Azure AI Foundry model deployments."
  value       = try(module.cloud_ai_foundry[0].deployments, null)
}
