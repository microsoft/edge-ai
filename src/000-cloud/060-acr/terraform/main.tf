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

  // optional parameters
  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint

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

  // optional parameters
  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
  sku                                = var.sku
}
