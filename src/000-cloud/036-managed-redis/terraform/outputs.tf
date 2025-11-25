/*
 * Redis Cache Outputs
 */

output "connection_info" {
  description = "Redis connection information."
  value       = try(module.managed_redis[0].connection_info, null)
  sensitive   = true
}

output "managed_redis" {
  description = "Azure Managed Redis cache details."
  value       = try(module.managed_redis[0].managed_redis, null)
}

/*
 * Private Endpoint Outputs
 */

output "private_endpoint" {
  description = "Private endpoint details when enabled."
  value       = try(module.managed_redis[0].private_endpoint, null)
}

/*
 * Dependency Management Outputs
 */

output "defer" {
  description = "Deferred output for dependency management."
  value       = terraform_data.defer
}
