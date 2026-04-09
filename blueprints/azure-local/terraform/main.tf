/**
 * # Azure Local IoT Operations Blueprint
 *
 * Deploys the cloud and edge resources required to run Azure IoT Operations on an Azure Arc-enabled Azure Local device.
 */

locals {
  use_separate_arc_rg = var.arc_cluster_resource_group_name != null && var.arc_cluster_resource_group_name != ""
}

resource "terraform_data" "defer" {
  input = {
    logical_network_name                = var.logical_network_name
    logical_network_resource_group_name = var.logical_network_resource_group_name
  }
}

module "arc_cluster_resource_group" {
  count  = local.use_separate_arc_rg ? 1 : 0
  source = "../../../src/000-cloud/000-resource-group/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  use_existing_resource_group = var.use_existing_resource_group_for_arc_cluster
  resource_group_name         = var.arc_cluster_resource_group_name
}

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  use_existing_resource_group = var.use_existing_resource_group_for_cloud
  resource_group_name         = var.resource_group_name
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = module.cloud_resource_group.resource_group

  // Private endpoint configuration
  should_create_key_vault_private_endpoint = false
  key_vault_private_endpoint_subnet_id     = null
  key_vault_virtual_network_id             = null
  should_enable_public_network_access      = var.should_enable_key_vault_public_network_access
  should_create_aks_identity               = false
  should_create_ml_workload_identity       = false
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  azmon_resource_group = module.cloud_resource_group.resource_group

  should_enable_private_endpoints = false
  private_endpoint_subnet_id      = null
  virtual_network_id              = null
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  should_enable_private_endpoint      = false
  private_endpoint_subnet_id          = null
  virtual_network_id                  = null
  should_enable_public_network_access = var.should_enable_storage_public_network_access
  storage_account_is_hns_enabled      = var.storage_account_is_hns_enabled
  should_create_data_lake             = var.should_create_data_lake
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

module "azure_local_host" {
  source = "../../../src/000-cloud/072-azure-local-host/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group                      = local.use_separate_arc_rg ? module.arc_cluster_resource_group[0].resource_group : module.cloud_resource_group.resource_group
  custom_locations_oid                = var.custom_locations_oid
  logical_network_name                = terraform_data.defer.output.logical_network_name
  logical_network_resource_group_name = terraform_data.defer.output.logical_network_resource_group_name
  control_plane_count                 = var.azure_local_control_plane_count
  node_pool_count                     = var.azure_local_node_pool_count
  control_plane_vm_size               = var.azure_local_control_plane_vm_size
  node_pool_vm_size                   = var.azure_local_node_pool_vm_size
  pod_cidr                            = var.azure_local_pod_cidr
  aad_profile                         = var.azure_local_aad_profile
}

module "edge_arc_extensions" {
  source = "../../../src/100-edge/109-arc-extensions/terraform"

  depends_on = [module.azure_local_host]

  arc_connected_cluster = module.azure_local_host
}

module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.edge_arc_extensions, module.cloud_security_identity]

  adr_schema_registry   = module.cloud_data.schema_registry
  adr_namespace         = module.cloud_data.adr_namespace
  resource_group        = local.use_separate_arc_rg ? module.arc_cluster_resource_group[0].resource_group : module.cloud_resource_group.resource_group
  aio_identity          = module.cloud_security_identity.aio_identity
  arc_connected_cluster = module.azure_local_host
  secret_sync_key_vault = module.cloud_security_identity.key_vault
  secret_sync_identity  = module.cloud_security_identity.secret_sync_identity

  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  aio_features            = var.aio_features
  enable_opc_ua_simulator = var.should_enable_opc_ua_simulator
}

module "edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.edge_iot_ops]

  location           = var.location
  resource_group     = module.cloud_resource_group.resource_group
  custom_location_id = module.edge_iot_ops.custom_locations.id
  adr_namespace      = module.cloud_data.adr_namespace

  should_create_default_asset = var.should_enable_opc_ua_simulator
  asset_endpoint_profiles     = var.asset_endpoint_profiles
  assets                      = var.assets
}

module "edge_observability" {
  source = "../../../src/100-edge/120-observability/terraform"

  depends_on = [module.edge_iot_ops]

  aio_azure_managed_grafana        = module.cloud_observability.azure_managed_grafana
  aio_azure_monitor_workspace      = module.cloud_observability.azure_monitor_workspace
  aio_log_analytics_workspace      = module.cloud_observability.log_analytics_workspace
  aio_logs_data_collection_rule    = module.cloud_observability.logs_data_collection_rule
  aio_metrics_data_collection_rule = module.cloud_observability.metrics_data_collection_rule
  resource_group                   = module.cloud_resource_group.resource_group
  arc_connected_cluster            = module.azure_local_host
}

module "edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  depends_on = [module.edge_observability]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_custom_locations = module.edge_iot_ops.custom_locations
  aio_dataflow_profile = module.edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.edge_iot_ops.aio_instance
  aio_identity         = module.cloud_security_identity.aio_identity
  eventgrid            = module.cloud_messaging.eventgrid
  eventhub             = module.cloud_messaging.eventhubs[0]
}
