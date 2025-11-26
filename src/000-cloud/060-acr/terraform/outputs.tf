output "acr" {
  description = "The Azure Container Registry resource created by this module, including network posture metadata."
  value       = module.container_registry.acr
}

output "acr_network_posture" {
  description = "Network posture for the Azure Container Registry, including public endpoint status, allow list, trusted services, and data endpoints."
  value = {
    allow_trusted_services        = module.container_registry.acr.allow_trusted_services
    allowed_public_ip_ranges      = module.container_registry.acr.allowed_public_ip_ranges
    data_endpoint_enabled         = module.container_registry.acr.data_endpoint_enabled
    network_rule_bypass_option    = module.container_registry.acr.network_rule_bypass_option
    public_network_access_enabled = module.container_registry.acr.public_network_access_enabled
  }
}
