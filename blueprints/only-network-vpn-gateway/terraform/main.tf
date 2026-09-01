/**
 * # Only Network VPN Gateway Blueprint
 *
 * Deploys a standalone resource group, virtual network, and VPN Gateway for Point-to-Site
 * client connectivity. This is Step 1 of a two-step deployment pattern: deploy this blueprint,
 * connect over VPN, then layer `full-multi-node-cluster` (with `use_existing_networking = true`)
 * on top of the resulting virtual network to safely disable public network access once connected.
 */

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags            = merge({ blueprint = "only-network-vpn-gateway" }, var.tags)
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  use_existing_resource_group = var.use_existing_resource_group
  resource_group_name         = var.resource_group_name
}

module "cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  virtual_network_config           = var.virtual_network_config
  should_enable_private_resolver   = var.should_enable_private_resolver
  resolver_subnet_address_prefix   = var.resolver_subnet_address_prefix
  default_outbound_access_enabled  = false
  should_enable_nat_gateway        = var.should_enable_managed_outbound_access
  nat_gateway_idle_timeout_minutes = var.nat_gateway_idle_timeout_minutes
  nat_gateway_public_ip_count      = var.nat_gateway_public_ip_count
  nat_gateway_zones                = var.nat_gateway_zones
}

// Key Vault only, needed to store the generated CA/client certificates for certificate-based VPN auth.
module "cloud_security_identity" {
  count  = var.vpn_gateway_should_use_azure_ad_auth ? 0 : 1
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = module.cloud_resource_group.resource_group

  should_create_key_vault  = true
  should_create_identities = false
}

module "cloud_vpn_gateway" {
  source = "../../../src/000-cloud/055-vpn-gateway/terraform"

  depends_on = [module.cloud_networking]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group                  = module.cloud_resource_group.resource_group
  virtual_network                     = module.cloud_networking.virtual_network
  key_vault                           = var.vpn_gateway_should_use_azure_ad_auth ? null : module.cloud_security_identity[0].key_vault
  vpn_gateway_config                  = var.vpn_gateway_config
  vpn_gateway_subnet_address_prefixes = var.vpn_gateway_subnet_address_prefixes
  should_use_azure_ad_auth            = var.vpn_gateway_should_use_azure_ad_auth
  should_generate_ca                  = var.vpn_gateway_should_generate_ca
  existing_certificate_name           = var.existing_certificate_name
  certificate_validity_days           = var.certificate_validity_days
  certificate_subject                 = var.certificate_subject
  default_outbound_access_enabled     = false
  vpn_site_connections                = var.vpn_site_connections
  vpn_site_default_ipsec_policy       = var.vpn_site_default_ipsec_policy
  vpn_site_shared_keys                = var.vpn_site_shared_keys
}
