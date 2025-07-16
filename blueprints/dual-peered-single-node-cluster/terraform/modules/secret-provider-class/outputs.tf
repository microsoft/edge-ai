/*
 * Secret Provider Class Outputs
 */

output "cluster_a_secret_provider_class" {
  description = "The Secret Provider Class resource for Cluster A."
  value       = azapi_resource.cluster_a_secret_provider_class
}

output "cluster_b_secret_provider_class" {
  description = "The Secret Provider Class resource for Cluster B."
  value       = azapi_resource.cluster_b_secret_provider_class
}

output "secret_sync_dependency" {
  description = "Dependency marker for secret synchronization setup completion."
  value       = "secret-provider-classes-configured"
}
