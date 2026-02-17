/**
 * # Leak Detection Blueprint
 *
 * Deploys a single-node Azure IoT Operations cluster optimized for
 * leak detection in Oil & Gas / Energy environments. Provisions cloud
 * foundation, edge infrastructure, asset definitions, and EventHub
 * dataflows for streaming ALERT_DLQC events to the cloud.
 */

locals {
  default_outbound_access_enabled = var.should_enable_managed_outbound_access == false

  acr_registry_endpoint = var.should_include_acr_registry_endpoint ? [{
    name                           = "acr-${var.resource_prefix}"
    host                           = "${module.cloud_acr.acr.name}.azurecr.io"
    acr_resource_id                = module.cloud_acr.acr.id
    should_assign_acr_pull_for_aio = true
    authentication = {
      method                                    = "SystemAssignedManagedIdentity"
      system_assigned_managed_identity_settings = null
      user_assigned_managed_identity_settings   = null
      artifact_pull_secret_settings             = null
    }
  }] : []

  combined_registry_endpoints = concat(var.registry_endpoints, local.acr_registry_endpoint)
}

// ── Cloud Foundation ──────────────────────────────────────────

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "leak-detection"
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Optional parameters for using an existing resource group
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

  should_enable_private_resolver  = var.should_enable_private_resolver
  resolver_subnet_address_prefix  = var.resolver_subnet_address_prefix
  default_outbound_access_enabled = local.default_outbound_access_enabled
  should_enable_nat_gateway       = var.should_enable_managed_outbound_access

  nat_gateway_idle_timeout_minutes = var.nat_gateway_idle_timeout_minutes
  nat_gateway_public_ip_count      = var.nat_gateway_public_ip_count
  nat_gateway_zones                = var.nat_gateway_zones
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = module.cloud_resource_group.resource_group

  should_create_key_vault_private_endpoint = var.should_enable_private_endpoints
  key_vault_private_endpoint_subnet_id     = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  key_vault_virtual_network_id             = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
  should_enable_public_network_access      = var.should_enable_key_vault_public_network_access
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  azmon_resource_group = module.cloud_resource_group.resource_group

  should_enable_private_endpoints = var.should_enable_private_endpoints
  private_endpoint_subnet_id      = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  virtual_network_id              = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  should_enable_private_endpoint      = var.should_enable_private_endpoints
  private_endpoint_subnet_id          = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  virtual_network_id                  = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
  should_enable_public_network_access = var.should_enable_storage_public_network_access
  storage_account_is_hns_enabled      = var.storage_account_is_hns_enabled

  should_create_blob_dns_zone = !var.should_enable_private_endpoints
  blob_dns_zone               = var.should_enable_private_endpoints ? module.cloud_observability.blob_private_dns_zone : null
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

// ── VM Host and Container Registry ───────────────────────────

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
  should_enable_nat_gateway          = var.should_enable_managed_outbound_access
  sku                                = var.acr_sku
  allow_trusted_services             = var.acr_allow_trusted_services
  allowed_public_ip_ranges           = var.acr_allowed_public_ip_ranges
  public_network_access_enabled      = var.acr_public_network_access_enabled
  should_enable_data_endpoints       = var.acr_data_endpoint_enabled
}

// ── Edge Foundation ──────────────────────────────────────────

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

  should_deploy_arc_machines            = false
  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  custom_locations_oid                  = var.custom_locations_oid

  key_vault = module.cloud_security_identity.key_vault
}

module "edge_arc_extensions" {
  source = "../../../src/100-edge/109-arc-extensions/terraform"

  depends_on = [module.edge_cncf_cluster]

  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
}

module "edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.edge_arc_extensions]

  adr_schema_registry   = module.cloud_data.schema_registry
  adr_namespace         = module.cloud_data.adr_namespace
  resource_group        = module.cloud_resource_group.resource_group
  aio_identity          = module.cloud_security_identity.aio_identity
  arc_connected_cluster = module.edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cloud_security_identity.key_vault
  secret_sync_identity  = module.cloud_security_identity.secret_sync_identity

  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  aio_features                       = var.aio_features
  enable_opc_ua_simulator            = var.should_enable_opc_ua_simulator
  should_enable_akri_rest_connector  = var.should_enable_akri_rest_connector
  should_enable_akri_media_connector = var.should_enable_akri_media_connector
  should_enable_akri_onvif_connector = var.should_enable_akri_onvif_connector
  should_enable_akri_sse_connector   = true
  custom_akri_connectors             = var.custom_akri_connectors
  registry_endpoints                 = local.combined_registry_endpoints
}

// ── Leak Detection Assets ────────────────────────────────────

module "edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.edge_iot_ops]

  location           = var.location
  resource_group     = module.cloud_resource_group.resource_group
  custom_location_id = module.edge_iot_ops.custom_locations.id
  adr_namespace      = module.cloud_data.adr_namespace

  should_create_default_namespaced_asset = var.should_enable_opc_ua_simulator
  namespaced_devices                     = var.namespaced_devices
  namespaced_assets                      = var.namespaced_assets
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
  arc_connected_cluster            = module.edge_cncf_cluster.arc_connected_cluster
}

module "edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  depends_on = [module.edge_iot_ops]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_custom_locations = module.edge_iot_ops.custom_locations
  aio_dataflow_profile = module.edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.edge_iot_ops.aio_instance
  aio_identity         = module.cloud_security_identity.aio_identity
  eventgrid            = module.cloud_messaging.eventgrid
  eventhub             = module.cloud_messaging.eventhubs[0]
  adr_namespace        = module.cloud_data.adr_namespace

  should_create_eventhub_dataflows  = true
  should_create_eventgrid_dataflows = false
}
