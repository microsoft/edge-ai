/**
 * # Minimum Single Node Cluster Blueprint
 *
 * This blueprint provides the minimal set of resources required to deploy
 * Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.
 * It includes only the essential components and minimizes resource usage.
 */

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "minimum-single-cluster"
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = module.cloud_resource_group.resource_group
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  // Minimize resource usage
  storage_account_tier        = "Standard"
  storage_account_replication = "LRS"
}

module "cloud_vm_host" {
  source = "../../../src/000-cloud/050-vm-host/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group          = module.cloud_resource_group.resource_group
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity

  // Minimize resource usage - set smaller VM size
  vm_sku_size = "Standard_D4s_v3"

  // Only create a single VM
  host_machine_count = 1
}

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group                 = module.cloud_resource_group.resource_group
  arc_onboarding_identity        = module.cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp              = module.cloud_security_identity.arc_onboarding_sp
  cluster_server_virtual_machine = module.cloud_vm_host.virtual_machines[0]

  should_get_custom_locations_oid = var.should_get_custom_locations_oid
  custom_locations_oid            = var.custom_locations_oid
}

module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  adr_schema_registry   = module.cloud_data.schema_registry
  resource_group        = module.cloud_resource_group.resource_group
  aio_identity          = module.cloud_security_identity.aio_identity
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cloud_security_identity.key_vault
  secret_sync_identity  = module.cloud_security_identity.secret_sync_identity

  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  // Minimize resource usage
  enable_opc_ua_simulator      = false
  should_enable_otel_collector = false
}
