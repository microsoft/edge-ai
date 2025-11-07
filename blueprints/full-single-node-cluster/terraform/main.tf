/**
 * # Full Single Node Cluster Blueprint
 *
 * This blueprint deploys a complete Azure IoT Operations environment with all cloud and edge components
 * for a single-node cluster deployment, including observability, messaging, and data management.
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

module "cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  # Private Resolver configuration
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

  # Private endpoint configuration
  should_create_key_vault_private_endpoint = var.should_enable_private_endpoints
  key_vault_private_endpoint_subnet_id     = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  key_vault_virtual_network_id             = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
  should_enable_public_network_access      = var.should_enable_key_vault_public_network_access
  should_create_aks_identity               = var.should_create_aks_identity
  should_create_ml_workload_identity       = var.azureml_should_create_ml_workload_identity
}

module "cloud_vpn_gateway" {
  count  = var.should_enable_vpn_gateway ? 1 : 0
  source = "../../../src/000-cloud/055-vpn-gateway/terraform"

  depends_on = [module.cloud_networking, module.cloud_security_identity]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group                  = module.cloud_resource_group.resource_group
  virtual_network                     = module.cloud_networking.virtual_network
  key_vault                           = var.should_enable_private_endpoints ? module.cloud_security_identity.key_vault : null
  vpn_gateway_config                  = var.vpn_gateway_config
  vpn_gateway_subnet_address_prefixes = var.vpn_gateway_subnet_address_prefixes
  should_use_azure_ad_auth            = var.vpn_gateway_should_use_azure_ad_auth
  should_generate_ca                  = var.vpn_gateway_should_generate_ca
  existing_certificate_name           = var.existing_certificate_name
  certificate_validity_days           = var.certificate_validity_days
  certificate_subject                 = var.certificate_subject
  default_outbound_access_enabled     = local.default_outbound_access_enabled
  vpn_site_connections                = var.vpn_site_connections
  vpn_site_default_ipsec_policy       = var.vpn_site_default_ipsec_policy
  vpn_site_shared_keys                = var.vpn_site_shared_keys
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  azmon_resource_group = module.cloud_resource_group.resource_group

  # Private endpoint configuration
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

  # Private endpoint configuration
  should_enable_private_endpoint      = var.should_enable_private_endpoints
  private_endpoint_subnet_id          = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  virtual_network_id                  = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
  should_enable_public_network_access = var.should_enable_storage_public_network_access
  storage_account_is_hns_enabled      = var.storage_account_is_hns_enabled && !var.should_deploy_azureml

  should_create_blob_dns_zone = !var.should_enable_private_endpoints
  blob_dns_zone               = var.should_enable_private_endpoints ? module.cloud_observability.blob_private_dns_zone : null
}

module "cloud_postgresql" {
  count  = var.should_deploy_postgresql ? 1 : 0
  source = "../../../src/000-cloud/035-postgresql/terraform"

  depends_on = [module.cloud_networking, module.cloud_security_identity]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group  = module.cloud_resource_group.resource_group
  virtual_network = module.cloud_networking.virtual_network
  key_vault       = module.cloud_security_identity.key_vault

  delegated_subnet_id = var.postgresql_delegated_subnet_id

  admin_username                        = var.postgresql_admin_username
  admin_password                        = var.postgresql_admin_password
  should_generate_admin_password        = var.postgresql_should_generate_admin_password
  should_store_credentials_in_key_vault = var.postgresql_should_store_credentials_in_key_vault

  postgres_version                   = var.postgresql_version
  sku_name                           = var.postgresql_sku_name
  storage_mb                         = var.postgresql_storage_mb
  should_enable_extensions           = var.postgresql_should_enable_extensions
  should_enable_timescaledb          = var.postgresql_should_enable_timescaledb
  should_enable_geo_redundant_backup = var.postgresql_should_enable_geo_redundant_backup
  databases                          = var.postgresql_databases
}

module "cloud_managed_redis" {
  count  = var.should_deploy_redis ? 1 : 0
  source = "../../../src/000-cloud/036-managed-redis/terraform"

  depends_on = [module.cloud_networking, module.cloud_security_identity]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group = module.cloud_resource_group.resource_group

  // Private endpoint configuration
  should_enable_private_endpoint = var.should_enable_private_endpoints
  private_endpoint_subnet = var.should_enable_private_endpoints ? {
    id = module.cloud_networking.subnet_id
  } : null
  virtual_network = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network : null

  // Entra ID authentication (default)
  access_keys_authentication_enabled = false
  managed_identity                   = module.cloud_security_identity.aio_identity

  // Redis configuration
  sku_name                        = var.redis_sku_name
  should_enable_high_availability = var.redis_should_enable_high_availability
  clustering_policy               = var.redis_clustering_policy
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

module "cloud_kubernetes" {
  count = var.should_create_aks ? 1 : 0

  source = "../../../src/000-cloud/070-kubernetes/terraform"

  depends_on = [module.cloud_networking, module.cloud_acr, module.cloud_observability]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group    = module.cloud_resource_group.resource_group
  should_create_aks = true

  network_security_group = module.cloud_networking.network_security_group
  virtual_network        = module.cloud_networking.virtual_network
  nat_gateway            = module.cloud_networking.nat_gateway

  acr                          = module.cloud_acr.acr
  log_analytics_workspace      = module.cloud_observability.log_analytics_workspace
  metrics_data_collection_rule = module.cloud_observability.metrics_data_collection_rule
  logs_data_collection_rule    = module.cloud_observability.logs_data_collection_rule
  aks_identity                 = module.cloud_security_identity.aks_identity

  default_outbound_access_enabled = local.default_outbound_access_enabled
  should_enable_nat_gateway       = var.should_enable_managed_outbound_access

  node_count                      = var.node_count
  node_vm_size                    = var.node_vm_size
  node_pools                      = var.node_pools
  should_enable_workload_identity = var.should_enable_workload_identity
  should_enable_oidc_issuer       = var.should_enable_oidc_issuer

  # Private cluster configuration
  should_enable_private_cluster             = var.aks_should_enable_private_cluster
  should_enable_private_cluster_public_fqdn = var.aks_should_enable_private_cluster_public_fqdn
  should_enable_private_endpoint            = var.should_enable_private_endpoints
  private_endpoint_subnet_id                = module.cloud_networking.subnet_id
}

module "cloud_azureml" {
  count = var.should_deploy_azureml ? 1 : 0

  source = "../../../src/000-cloud/080-azureml/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  resource_group         = module.cloud_resource_group.resource_group
  application_insights   = try(module.cloud_observability.application_insights, null)
  key_vault              = try(module.cloud_security_identity.key_vault, null)
  storage_account        = try(module.cloud_data.storage_account, null)
  acr                    = try(module.cloud_acr.acr, null)
  network_security_group = try(module.cloud_networking.network_security_group, null)
  virtual_network        = try(module.cloud_networking.virtual_network, null)
  nat_gateway            = try(module.cloud_networking.nat_gateway, null)
  kubernetes             = try(module.cloud_kubernetes[0].aks, null)

  default_outbound_access_enabled         = local.default_outbound_access_enabled
  should_associate_network_security_group = true
  should_enable_nat_gateway               = var.should_enable_managed_outbound_access
  should_enable_public_network_access     = var.azureml_should_enable_public_network_access
  should_create_compute_cluster           = var.azureml_should_create_compute_cluster
  ml_workload_identity                    = try(module.cloud_security_identity.ml_workload_identity, null)
  ml_workload_subjects                    = var.azureml_ml_workload_subjects

  should_assign_ml_workload_identity_roles = var.azureml_should_create_ml_workload_identity

  // Private endpoint configuration
  should_enable_private_endpoint               = var.azureml_should_enable_private_endpoint
  private_endpoint_subnet_id                   = var.azureml_should_enable_private_endpoint ? module.cloud_networking.subnet_id : null
  should_deploy_registry                       = var.azureml_should_deploy_registry
  registry_should_enable_public_network_access = var.azureml_registry_should_enable_public_network_access

  // Registry dependencies
  registry_storage_account = try(module.cloud_data.storage_account, null)
  registry_acr             = try(module.cloud_acr.acr, null)
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

  should_deploy_arc_machines            = false
  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  custom_locations_oid                  = var.custom_locations_oid

  // Key Vault for script retrieval
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
}

module "edge_azureml" {
  count  = var.should_deploy_azureml && var.should_deploy_edge_azureml ? 1 : 0
  source = "../../../src/100-edge/140-azureml/terraform"

  depends_on = [module.cloud_azureml]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = var.location

  machine_learning_workspace = module.cloud_azureml[0].azureml_workspace

  should_enable_inference_router_ha = false

  connected_cluster               = module.edge_cncf_cluster.arc_connected_cluster
  resource_group                  = module.cloud_resource_group.resource_group
  workspace_identity_principal_id = module.cloud_azureml[0].workspace_principal_id
  ml_workload_identity            = module.cloud_security_identity.ml_workload_identity
  ml_workload_subjects            = var.azureml_ml_workload_subjects
}
