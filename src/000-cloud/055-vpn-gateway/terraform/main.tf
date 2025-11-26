/**
 * # VPN Gateway
 *
 * Creates a VPN Gateway with Point-to-Site configuration to provide secure
 * remote access to Azure services through private endpoints. Supports both
 * certificate-based and Azure Entra ID authentication methods.
 */

locals {
  vpn_site_default_ipsec_policy = try(var.vpn_site_default_ipsec_policy, null)
  vpn_site_connections = [
    for site in var.vpn_site_connections :
    merge(site, {
      ipsec_policy = try(coalesce(site.ipsec_policy, local.vpn_site_default_ipsec_policy), null)
    })
  ]
}

module "certificate_management" {
  count = !var.should_use_azure_ad_auth ? 1 : 0

  source = "./modules/certificate-management"

  key_vault                 = var.key_vault
  should_generate_ca        = var.should_generate_ca
  existing_certificate_name = var.existing_certificate_name
  certificate_validity_days = var.certificate_validity_days
  certificate_subject       = var.certificate_subject
  resource_prefix           = var.resource_prefix
  environment               = var.environment
  instance                  = var.instance
}

module "vpn_gateway" {
  source = "./modules/vpn-gateway"

  depends_on = [module.certificate_management]

  location                            = var.location
  resource_group                      = var.aio_resource_group
  resource_prefix                     = var.resource_prefix
  environment                         = var.environment
  instance                            = var.instance
  virtual_network                     = var.virtual_network
  vpn_gateway_config                  = var.vpn_gateway_config
  vpn_gateway_subnet_address_prefixes = var.vpn_gateway_subnet_address_prefixes
  default_outbound_access_enabled     = var.default_outbound_access_enabled

  should_use_azure_ad_auth = var.should_use_azure_ad_auth
  azure_ad_config          = var.azure_ad_config

  root_certificate_name        = try(module.certificate_management[0].certificate_name, null)
  root_certificate_public_data = try(module.certificate_management[0].public_certificate_data, null)
}

module "site_to_site" {
  count = length(local.vpn_site_connections) > 0 ? 1 : 0

  source = "./modules/site-to-site"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_group  = var.aio_resource_group
  resource_prefix = var.resource_prefix
  vpn_gateway_id  = module.vpn_gateway.vpn_gateway.id
  sites           = local.vpn_site_connections
  shared_keys     = var.vpn_site_shared_keys
}
