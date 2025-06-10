/**
 * # Partial Single Node Cluster Blueprint
 *
 * This blueprint is designed to deploy a single-node, Arc-enabled Kubernetes cluster without Azure IoT Operations.
 * It focuses solely on the edge CNCF cluster component without any other edge components
 * such as IoT Ops, Observability, or Messaging.
 *
 * This blueprint will:
 *
 * 1. Deploy required cloud components (Resource Group, Security/Identity, VM Host)
 * 2. Deploy the CNCF cluster using scripts from Key Vault
 * 3. Ensure proper role assignments for Key Vault access
 */

/*
 * Cloud Components
 */

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = var.location
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = var.location

  aio_resource_group = module.cloud_resource_group.resource_group
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
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = var.location

  resource_group          = module.cloud_resource_group.resource_group
  subnet_id               = module.cloud_networking.subnet_id
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
}

/*
 * Edge Components
 */

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group          = module.cloud_resource_group.resource_group
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp       = module.cloud_security_identity.arc_onboarding_sp
  cluster_server_machine  = module.cloud_vm_host.virtual_machines[0]

  should_deploy_arc_machines      = false
  should_get_custom_locations_oid = var.should_get_custom_locations_oid
  custom_locations_oid            = var.custom_locations_oid

  // Key Vault configuration
  key_vault                                 = module.cloud_security_identity.key_vault
  should_upload_to_key_vault                = true
  should_use_script_from_secrets_for_deploy = true
  should_assign_roles                       = true
}
