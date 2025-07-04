/**
 * # Full Cloud Single Node Cluster Blueprint
 *
 * This blueprint deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.
 */

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

  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
}

module "cloud_kubernetes" {
  source = "../../../src/000-cloud/070-kubernetes/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  network_security_group = module.cloud_networking.network_security_group
  virtual_network        = module.cloud_networking.virtual_network

  acr = module.cloud_acr.acr

  should_create_aks = var.should_create_aks
}
