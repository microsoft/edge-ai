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
 * Custom Script Deployment Outputs
 */

output "server_central_script_deployment" {
  description = "The server central script deployment extension on Cluster A."
  value       = module.custom_script_deployment.server_central_script_deployment
}

output "client_technology_script_deployment" {
  description = "The client technology script deployment extension on Cluster B."
  value       = module.custom_script_deployment.client_technology_script_deployment
}

/*
 * Certificate Generation Outputs
 */

output "certificate_generation_status" {
  description = "Status of the certificate generation process."
  value = var.should_create_certificates ? (
    var.use_terraform_certificates ? {
      status = "completed"
      method = "terraform"
      result = try(module.terraform_certificate_generation[0].certificate_dependency, null)
      } : {
      status = "completed"
      method = "step-cli"
      result = try(module.certificate_generation[0].certificate_dependency, null)
    }
    ) : {
    status = "skipped"
    method = "none"
    result = null
  }
}

output "terraform_certificate_files" {
  description = "List of certificate files created by Terraform TLS provider (when use_terraform_certificates is true)."
  value = var.should_create_certificates && var.use_terraform_certificates ? {
    files               = try(module.terraform_certificate_generation[0].certificate_files, [])
    server_root_ca_cert = try(module.terraform_certificate_generation[0].server_root_ca_cert, null)
    server_leaf_cert    = try(module.terraform_certificate_generation[0].server_leaf_cert, null)
    client_root_ca_cert = try(module.terraform_certificate_generation[0].client_root_ca_cert, null)
    client_leaf_cert    = try(module.terraform_certificate_generation[0].client_leaf_cert, null)
  } : null
  sensitive = false
}

/*
 * Secret Provider Class Outputs
 */

output "secret_provider_class_status" {
  description = "Status of the secret provider class configuration."
  value = var.should_create_certificates ? {
    status        = "skipped"
    cluster_a_spc = null
    cluster_b_spc = null
    } : {
    status        = "completed"
    cluster_a_spc = try(module.secret_provider_class[0].cluster_a_secret_provider_class, null)
    cluster_b_spc = try(module.secret_provider_class[0].cluster_b_secret_provider_class, null)
  }
}
