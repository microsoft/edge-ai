/**
 * # Full Cloud Single Node Cluster Blueprint
 *
 * This blueprint deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.
 */

locals {
  default_outbound_access_enabled = var.should_enable_managed_outbound_access == false
}

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "full-single-cluster"
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Optional parameters for using an existing resource group
  use_existing_resource_group = var.use_existing_resource_group
  resource_group_name         = var.resource_group_name
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = module.cloud_resource_group.resource_group

  # Private endpoint configuration
  should_create_key_vault_private_endpoint = var.should_enable_private_endpoints
  key_vault_private_endpoint_subnet_id     = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  key_vault_virtual_network_id             = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  azmon_resource_group = module.cloud_resource_group.resource_group
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  # Private endpoint configuration
  should_enable_private_endpoint = var.should_enable_private_endpoints
  private_endpoint_subnet_id     = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  virtual_network_id             = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
}

module "cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  resource_group  = module.cloud_resource_group.resource_group
  aio_identity    = module.cloud_security_identity.aio_identity
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  should_create_azure_functions = var.should_create_azure_functions
}

module "cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  default_outbound_access_enabled  = local.default_outbound_access_enabled
  should_enable_nat_gateway        = var.should_enable_managed_outbound_access
  nat_gateway_idle_timeout_minutes = var.nat_gateway_idle_timeout_minutes
  nat_gateway_public_ip_count      = var.nat_gateway_public_ip_count
  nat_gateway_zones                = var.nat_gateway_zones
}

module "cloud_vm_host" {
  source = "../../../src/000-cloud/051-vm-host/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group          = module.cloud_resource_group.resource_group
  subnet_id               = module.cloud_networking.subnet_id
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
}

module "cloud_acr" {
  source = "../../../src/000-cloud/060-acr/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  network_security_group = module.cloud_networking.network_security_group
  virtual_network        = module.cloud_networking.virtual_network
  nat_gateway            = module.cloud_networking.nat_gateway

  should_create_acr_private_endpoint = var.should_enable_private_endpoints
  default_outbound_access_enabled    = local.default_outbound_access_enabled
}

module "cloud_kubernetes" {
  count = var.should_create_aks ? 1 : 0

  source = "../../../src/000-cloud/070-kubernetes/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group    = module.cloud_resource_group.resource_group
  should_create_aks = true

  network_security_group = module.cloud_networking.network_security_group
  virtual_network        = module.cloud_networking.virtual_network
  nat_gateway            = module.cloud_networking.nat_gateway

  acr = module.cloud_acr.acr

  default_outbound_access_enabled = local.default_outbound_access_enabled

  node_count                      = var.node_count
  node_vm_size                    = var.node_vm_size
  enable_auto_scaling             = var.enable_auto_scaling
  min_count                       = var.min_count
  max_count                       = var.max_count
  dns_prefix                      = var.dns_prefix
  subnet_address_prefixes_aks     = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod = var.subnet_address_prefixes_aks_pod
  node_pools                      = var.node_pools
}
