/*
 * Cluster A Outputs
 */

output "cluster_a_resource_group" {
  description = "The Cluster A resource group."
  value       = module.cluster_a_cloud_resource_group.resource_group
}

output "cluster_a_virtual_network" {
  description = "The Cluster A virtual network."
  value       = module.cluster_a_cloud_networking.virtual_network
}

output "cluster_a_nat_gateway" {
  description = "The Cluster A NAT gateway when managed outbound access is enabled."
  value       = module.cluster_a_cloud_networking.nat_gateway
}

output "cluster_a_nat_gateway_public_ips" {
  description = "The Cluster A NAT gateway public IP resources keyed by name."
  value       = module.cluster_a_cloud_networking.nat_gateway_public_ips
}

output "cluster_a_arc_connected_cluster" {
  description = "The Cluster A Arc connected cluster."
  value       = module.cluster_a_edge_cncf_cluster.arc_connected_cluster
}

output "cluster_a_aio_instance" {
  description = "The Cluster A AIO instance."
  value       = module.cluster_a_edge_iot_ops.aio_instance
}

output "cluster_a_azure_arc_proxy_command" {
  description = "The AZ CLI command to proxy to the Cluster A Arc Connected cluster."
  value       = module.cluster_a_edge_cncf_cluster.azure_arc_proxy_command
}

/*
 * Cluster B Outputs
 */

output "cluster_b_resource_group" {
  description = "The Cluster B resource group."
  value       = module.cluster_b_cloud_resource_group.resource_group
}

output "cluster_b_virtual_network" {
  description = "The Cluster B virtual network."
  value       = module.cluster_b_cloud_networking.virtual_network
}

output "cluster_b_nat_gateway" {
  description = "The Cluster B NAT gateway when managed outbound access is enabled."
  value       = module.cluster_b_cloud_networking.nat_gateway
}

output "cluster_b_nat_gateway_public_ips" {
  description = "The Cluster B NAT gateway public IP resources keyed by name."
  value       = module.cluster_b_cloud_networking.nat_gateway_public_ips
}

output "cluster_b_arc_connected_cluster" {
  description = "The Cluster B Arc connected cluster."
  value       = module.cluster_b_edge_cncf_cluster.arc_connected_cluster
}

output "cluster_b_aio_instance" {
  description = "The Cluster B AIO instance."
  value       = module.cluster_b_edge_iot_ops.aio_instance
}

output "cluster_b_azure_arc_proxy_command" {
  description = "The AZ CLI command to proxy to the Cluster B Arc Connected cluster."
  value       = module.cluster_b_edge_cncf_cluster.azure_arc_proxy_command
}

/*
 * Peering Outputs
 */

output "vnet_peering_cluster_a_to_cluster_b" {
  description = "The virtual network peering from Cluster A to Cluster B."
  value       = azurerm_virtual_network_peering.cluster_a_to_cluster_b
}

output "vnet_peering_cluster_b_to_cluster_a" {
  description = "The virtual network peering from Cluster B to Cluster A."
  value       = azurerm_virtual_network_peering.cluster_b_to_cluster_a
}

/*
 * Secret Provider Class Outputs
 */

output "secret_provider_class_status" {
  description = "Status of the secret provider class configuration."
  value = {
    status        = "completed"
    cluster_a_spc = try(module.secret_provider_class.cluster_a_secret_provider_class, null)
    cluster_b_spc = try(module.secret_provider_class.cluster_b_secret_provider_class, null)
  }
}
