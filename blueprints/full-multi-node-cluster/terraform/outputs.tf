/*
 * Full Multi Node Cluster Blueprint Outputs
 */

output "container_registry" {
  description = "Azure Container Registry resources."
  value       = module.cloud_acr.acr
}

output "acr_network_posture" {
  description = "Azure Container Registry network posture metadata."
  value       = module.cloud_acr.acr_network_posture
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
