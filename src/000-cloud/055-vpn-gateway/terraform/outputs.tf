/*
 * VPN Gateway Outputs
 */

output "vpn_gateway" {
  description = "The VPN Gateway configuration and details"
  value       = module.vpn_gateway.vpn_gateway
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN Gateway"
  value       = module.vpn_gateway.public_ip_address
}

/*
 * Certificate Outputs
 */

output "root_certificate" {
  description = "The root certificate configuration for VPN clients. Only available when should_use_azure_ad_auth is false"
  value       = try(module.certificate_management[0], null)
  sensitive   = true
}

output "client_connection_info" {
  description = "Information for VPN client configuration"
  value = {
    vpn_gateway_public_ip = module.vpn_gateway.public_ip_address
    client_address_pool   = var.vpn_gateway_config.client_address_pool
    protocols             = var.vpn_gateway_config.protocols
  }
}

/*
 * Site-to-Site Outputs
 */

output "vpn_site_connections" {
  description = "Site-to-site VPN connection metadata keyed by site name"
  value       = try(module.site_to_site[0].site_connections, null)
}

output "vpn_site_local_network_gateways" {
  description = "Local network gateway metadata keyed by site name"
  value       = try(module.site_to_site[0].local_network_gateways, null)
}
