
/*
 * Kubernetes Cluster Outputs
 */

output "id" {
  description = "Resource ID of the Kubernetes connected cluster."
  value       = try(azapi_resource.connected_cluster.id, null)
}

output "name" {
  description = "Name of the Kubernetes connected cluster."
  value       = try(azapi_resource.connected_cluster.name, null)
}

output "location" {
  description = "Location of the Kubernetes connected cluster."
  value       = try(azapi_resource.connected_cluster.location, null)
}

output "cluster_id" {
  description = "Resource ID of the provisioned Kubernetes cluster instance."
  value       = try(azapi_resource.provisioned_cluster_instance.id, null)
}
