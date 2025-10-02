/**
 * Full Single Node Cluster Blueprint Outputs
 *
 * This file contains the outputs for the complete Azure IoT Operations deployment
 * including cloud resources, edge cluster, and applications.
 */

/*
 * Azure IoT Operations Outputs
 */

output "azure_iot_operations" {
  description = "Azure IoT Operations deployment details."
  value = {
    custom_location_id = module.edge_iot_ops.custom_locations.id
    instance_name      = module.edge_iot_ops.aio_instance.name
    mqtt_broker        = module.edge_iot_ops.aio_mqtt_broker.brokerListenerHostName
    mqtt_port_no_tls   = var.should_create_anonymous_broker_listener ? tostring(try(module.edge_iot_ops.aio_broker_listener_anonymous.port, "Not configured")) : "Not configured"
    mqtt_port_tls      = module.edge_iot_ops.aio_mqtt_broker.brokerListenerPort
    namespace          = module.edge_iot_ops.aio_namespace
  }
}

output "assets" {
  description = "IoT asset resources."
  value = {
    assets                  = module.edge_assets.assets
    asset_endpoint_profiles = module.edge_assets.asset_endpoint_profiles
  }
}

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

output "container_registry" {
  description = "Azure Container Registry resources."
  value       = module.cloud_acr.acr
}

output "acr_network_posture" {
  description = "Azure Container Registry network posture metadata."
  value       = module.cloud_acr.acr_network_posture
}

output "kubernetes" {
  description = "Azure Kubernetes Service resources."
  value       = try(module.cloud_kubernetes[0].aks, null)
}

/*
 * Data Storage Outputs
 */

output "data_storage" {
  description = "Data storage resources."
  value = {
    schema_registry_endpoint = try(module.cloud_data.schema_registry.endpoint, "Not deployed")
    schema_registry_name     = try(module.cloud_data.schema_registry.name, "Not deployed")
    storage_account_name     = try(module.cloud_data.storage_account.name, "Not deployed")
  }
}

/*
 * Deployment Summary Outputs
 */

output "deployment_summary" {
  description = "Summary of the deployment configuration."
  value = {
    resource_group = module.cloud_resource_group.resource_group.name
  }
}

/*
 * Networking Outputs
 */

output "nat_gateway" {
  description = "NAT gateway resource when managed outbound access is enabled."
  value       = module.cloud_networking.nat_gateway
}

output "nat_gateway_public_ips" {
  description = "Public IP resources associated with the NAT gateway keyed by name."
  value       = module.cloud_networking.nat_gateway_public_ips
}

/*
 * Messaging Outputs
 */

output "messaging" {
  description = "Cloud messaging resources."
  value = {
    event_grid_topic_endpoint = try(module.cloud_messaging.eventgrid.endpoint, "Not deployed")
    event_grid_topic_name     = try(module.cloud_messaging.eventgrid.name, "Not deployed")
    eventhub_name             = try(module.cloud_messaging.eventhubs[0].name, "Not deployed")
    eventhub_namespace_name   = try(module.cloud_messaging.eventhubs[0].namespace_name, "Not deployed")
  }
}

/*
 * Azure Machine Learning Outputs
 */

output "azureml_workspace" {
  description = "Azure Machine Learning workspace resources."
  value       = try(module.cloud_azureml[0].azureml_workspace, null)
}

output "azureml_compute_cluster" {
  description = "Azure Machine Learning compute cluster resources."
  value       = try(module.cloud_azureml[0].compute_cluster, null)
}

output "azureml_extension" {
  description = "Azure Machine Learning extension for AKS cluster integration."
  value       = try(module.cloud_azureml[0].azureml_extension, null)
}

output "azureml_inference_cluster" {
  description = "Azure Machine Learning inference cluster compute target for AKS integration."
  value       = try(module.cloud_azureml[0].inference_cluster_compute_target, null)
}

/*
 * Edge Infrastructure Outputs
 */

output "vm_host" {
  description = "Virtual machine host resources."
  value       = module.cloud_vm_host.virtual_machines
}

output "arc_connected_cluster" {
  description = "Azure Arc connected cluster resources."
  value       = module.edge_cncf_cluster.arc_connected_cluster
}

/*
 * Observability Outputs
 */

output "observability" {
  description = "Monitoring and observability resources."
  sensitive   = true
  value = {
    azure_monitor_workspace_name = try(module.cloud_observability.azure_monitor_workspace.name, "Not deployed")
    grafana_endpoint             = try(module.cloud_observability.azure_managed_grafana.endpoint, "Not deployed")
    grafana_name                 = try(module.cloud_observability.azure_managed_grafana.name, "Not deployed")
    log_analytics_workspace_name = try(module.cloud_observability.log_analytics_workspace.name, "Not deployed")
  }
}

/*
 * Security and Identity Outputs
 */

output "security_identity" {
  description = "Security and identity resources."
  value = {
    aio_identity   = try(module.cloud_security_identity.aio_identity.name, "Not deployed")
    key_vault_name = try(module.cloud_security_identity.key_vault.name, "Not deployed")
    key_vault_uri  = try(module.cloud_security_identity.key_vault.vault_uri, "Not deployed")
  }
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
  value       = try(module.cloud_networking.dns_server_ip, null)
}
