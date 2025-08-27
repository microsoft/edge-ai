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

  depends_on = [module.cloud_security_identity]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group          = module.cloud_resource_group.resource_group
  subnet_id               = module.cloud_networking.subnet_id
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity

  vm_sku_size = var.vm_sku_size

  // Only create a single VM
  host_machine_count = 1
}

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  depends_on = [module.cloud_vm_host]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group          = module.cloud_resource_group.resource_group
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp       = module.cloud_security_identity.arc_onboarding_sp
  cluster_server_machine  = module.cloud_vm_host.virtual_machines[0]

  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  custom_locations_oid                  = var.custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin

  key_vault = module.cloud_security_identity.key_vault
}

module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.edge_cncf_cluster]

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

module "edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.edge_iot_ops]

  location           = var.location
  resource_group     = module.cloud_resource_group.resource_group
  custom_location_id = module.edge_iot_ops.custom_locations.id

  should_create_default_asset = false
  asset_endpoint_profiles     = var.asset_endpoint_profiles
  assets                      = var.assets
}
