/*
 * Only Network VPN Gateway Blueprint Outputs
 */

output "resource_group" {
  description = "The resource group containing the networking and VPN gateway resources."
  value       = module.cloud_resource_group.resource_group
}

output "virtual_network" {
  description = "The virtual network object."
  value       = module.cloud_networking.virtual_network
}

output "subnet_id" {
  description = "The ID of the subnet used for private endpoints and workloads."
  value       = module.cloud_networking.subnet_id
}

output "vpn_gateway" {
  description = "The VPN Gateway configuration and details."
  value       = module.cloud_vpn_gateway.vpn_gateway
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN Gateway."
  value       = module.cloud_vpn_gateway.vpn_gateway_public_ip
}

output "vpn_client_connection_info" {
  description = "Information needed to generate and download the VPN client profile via az cli or the Azure Portal."
  value       = module.cloud_vpn_gateway.client_connection_info
}
