/**
 * # Full Arc Server Multi Node Cluster Blueprint
 *
 * Deploys a full deployment with (almost) all components onto Arc enabled Servers.
 */

/*
 * Arc Machine Resources
 */

resource "terraform_data" "defer" {
  input = {
    arc_machine_name_prefix = coalesce(var.arc_machine_name_prefix, var.resource_prefix)
  }
}

data "azurerm_arc_machine" "machines" {
  count = length(range(var.arc_machine_count))

  name                = "${terraform_data.defer.output.arc_machine_name_prefix}${count.index + 1}"
  resource_group_name = try(coalesce(var.arc_machine_resource_group_name, var.resource_group_name, module.cloud_resource_group.resource_group.name), null)
}

/*
 * Cloud Components
 */

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  tags                        = var.resource_group_tags
  resource_group_name         = var.resource_group_name
  use_existing_resource_group = var.use_existing_resource_group
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  aio_resource_group    = module.cloud_resource_group.resource_group
  onboard_identity_type = "skip"
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location

  azmon_resource_group = module.cloud_resource_group.resource_group
}

// Setups the Storage Account that's needed for the Schema Registry
module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  resource_group = module.cloud_resource_group.resource_group

  should_create_adr_namespace = var.should_create_adr_namespace
}

// Contains resources for Event Hubs and Event Grid
module "cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix

  resource_group = module.cloud_resource_group.resource_group
  aio_identity   = module.cloud_security_identity.aio_identity

  should_create_azure_functions = var.should_create_azure_functions
}

/*
 * Edge Components
 */

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix

  resource_group = module.cloud_resource_group.resource_group

  cluster_server_machine               = data.azurerm_arc_machine.machines[0]
  cluster_node_machine                 = slice(data.azurerm_arc_machine.machines, 1, length(data.azurerm_arc_machine.machines))
  cluster_server_ip                    = var.cluster_server_ip
  cluster_server_host_machine_username = var.cluster_server_host_machine_username

  // Only supporting Arc Enabled Servers
  should_deploy_arc_machines   = true
  arc_onboarding_principal_ids = data.azurerm_arc_machine.machines[*].identity[0].principal_id

  // Needed for now to create a server token before setting up server and nodes
  should_generate_cluster_server_token = true

  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  custom_locations_oid                  = var.custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin

  key_vault = module.cloud_security_identity.key_vault

  // Assign Arc Onboarding and Key Vault Secret Roles to arc_onboarding_principal_ids
  should_assign_roles = true
  // Upload scripts to Key Vault and deploy scripts from Key Vault
  should_upload_to_key_vault = true
}

module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.edge_cncf_cluster]

  adr_schema_registry   = module.cloud_data.schema_registry
  adr_namespace         = module.cloud_data.adr_namespace
  resource_group        = module.cloud_resource_group.resource_group
  aio_identity          = module.cloud_security_identity.aio_identity
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cloud_security_identity.key_vault
  secret_sync_identity  = module.cloud_security_identity.secret_sync_identity

  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener
  should_enable_otel_collector            = var.should_enable_otel_collector
  enable_opc_ua_simulator                 = var.should_enable_opc_ua_simulator
}

module "edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.edge_iot_ops]

  location           = var.location
  resource_group     = module.cloud_resource_group.resource_group
  custom_location_id = module.edge_iot_ops.custom_location_id
  adr_namespace      = module.cloud_data.adr_namespace

  should_create_default_namespaced_asset = var.should_enable_opc_ua_simulator
  namespaced_devices                     = var.namespaced_devices
  namespaced_assets                      = var.namespaced_assets
}

/*
 * Edge Observability Components
 */

module "edge_observability" {
  source = "../../../src/100-edge/120-observability/terraform"

  depends_on = [module.edge_iot_ops]

  aio_azure_managed_grafana        = module.cloud_observability.azure_managed_grafana
  aio_azure_monitor_workspace      = module.cloud_observability.azure_monitor_workspace
  aio_log_analytics_workspace      = module.cloud_observability.log_analytics_workspace
  aio_logs_data_collection_rule    = module.cloud_observability.logs_data_collection_rule
  aio_metrics_data_collection_rule = module.cloud_observability.metrics_data_collection_rule
  resource_group                   = module.cloud_resource_group.resource_group
  arc_connected_cluster            = module.edge_cncf_cluster.arc_connected_cluster
}

/*
 * Edge Messaging Components
 */

module "edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  depends_on = [module.edge_observability]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = "001"

  aio_custom_locations = module.edge_iot_ops.custom_locations
  aio_dataflow_profile = module.edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.edge_iot_ops.aio_instance
  aio_identity         = module.cloud_security_identity.aio_identity
  eventgrid            = module.cloud_messaging.eventgrid
  eventhub             = module.cloud_messaging.eventhubs[0]
}
