/**
 * # Azure Container Registry (ACR)
 *
 * Deploys Azure Container Registry resources
 */

module "network" {
  source = "./modules/network"

  // Resource dependencies first
  resource_group         = var.resource_group
  network_security_group = var.network_security_group
  virtual_network        = var.virtual_network

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Optional parameters
  default_outbound_access_enabled    = var.default_outbound_access_enabled
  nat_gateway_id                     = var.should_create_acr_private_endpoint ? try(var.nat_gateway.id, null) : null
  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
  subnet_address_prefixes_acr        = var.subnet_address_prefixes_acr
}

module "container_registry" {
  source = "./modules/container-registry"

  // Resource dependencies first
  resource_group = var.resource_group
  snet_acr       = module.network.snet_acr
  vnet           = var.virtual_network

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  // Optional parameters
  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
  allow_trusted_services             = var.allow_trusted_services
  allowed_public_ip_ranges           = var.allowed_public_ip_ranges
  public_network_access_enabled      = var.public_network_access_enabled
  sku                                = var.sku
  should_enable_data_endpoints       = var.should_enable_data_endpoints
}
