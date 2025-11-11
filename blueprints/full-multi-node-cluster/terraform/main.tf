/**
 * # Full Multi Node Cluster Blueprint (Updated)
 *
 * Deploys the complete Edge AI solution for a multi-node edge cluster, aligning module orchestration
 * with the single-node blueprint while preserving multi-node specific capabilities.
 */

locals {
  default_outbound_access_enabled = var.should_enable_managed_outbound_access == false
  should_use_arc_machines         = var.should_use_arc_machines
  vm_host_private_ips             = try(module.cloud_vm_host[0].private_ips, [])
  vm_host_virtual_machines        = try(module.cloud_vm_host[0].virtual_machines, [])
  cluster_machine_count           = local.should_use_arc_machines ? var.arc_machine_count : var.host_machine_count
  cluster_node_machine_count      = max(local.cluster_machine_count - 1, 0)
}

/*
 * Arc Machine Resources
 */

// Defer computation to prevent Arc machine lookups when Arc integration is disabled.
resource "terraform_data" "defer_arc_machine_prefix" {
  count = local.should_use_arc_machines ? 1 : 0

  input = {
    arc_machine_name_prefix = coalesce(var.arc_machine_name_prefix, var.resource_prefix)
  }
}

data "azurerm_arc_machine" "arc_machines" {
  count = local.should_use_arc_machines ? length(range(var.arc_machine_count)) : 0

  name                = "${terraform_data.defer_arc_machine_prefix[0].output.arc_machine_name_prefix}${count.index + 1}"
  resource_group_name = coalesce(var.arc_machine_resource_group_name, var.resource_group_name, module.cloud_resource_group.resource_group.name)
}

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "full-multi-cluster"
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

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
  storage_account_is_hns_enabled      = var.storage_account_is_hns_enabled && !var.should_deploy_azureml
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
  count  = local.should_use_arc_machines ? 0 : 1
  source = "../../../src/000-cloud/051-vm-host/terraform"

  depends_on = [module.cloud_security_identity]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  host_machine_count = var.host_machine_count

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
  sku                                = var.acr_sku
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

  acr                          = module.cloud_acr.acr
  log_analytics_workspace      = module.cloud_observability.log_analytics_workspace
  metrics_data_collection_rule = module.cloud_observability.metrics_data_collection_rule
  aks_identity                 = module.cloud_security_identity.aks_identity

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
  should_enable_workload_identity = var.should_enable_workload_identity
  should_enable_oidc_issuer       = var.should_enable_oidc_issuer

  should_enable_private_cluster             = var.aks_should_enable_private_cluster
  should_enable_private_cluster_public_fqdn = var.aks_should_enable_private_cluster_public_fqdn
  private_dns_zone_id                       = var.aks_private_dns_zone_id
  should_enable_private_endpoint            = var.should_enable_private_endpoints
  private_endpoint_subnet_id                = var.should_enable_private_endpoints ? module.cloud_networking.subnet_id : null
  virtual_network_id                        = var.should_enable_private_endpoints ? module.cloud_networking.virtual_network.id : null
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

  default_outbound_access_enabled     = local.default_outbound_access_enabled
  should_enable_public_network_access = var.azureml_should_enable_public_network_access
  should_create_compute_cluster       = var.azureml_should_create_compute_cluster
  ml_workload_identity                = try(module.cloud_security_identity.ml_workload_identity, null)
  ml_workload_subjects                = var.azureml_ml_workload_subjects

  // Private endpoint configuration
  should_enable_private_endpoint               = var.azureml_should_enable_private_endpoint
  private_endpoint_subnet_id                   = var.azureml_should_enable_private_endpoint ? module.cloud_networking.subnet_id : null
  virtual_network_id                           = var.azureml_should_enable_private_endpoint ? module.cloud_networking.virtual_network.id : null
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
  arc_onboarding_principal_ids = length(data.azurerm_arc_machine.arc_machines) > 0 ? [
    for machine in data.azurerm_arc_machine.arc_machines : machine.identity[0].principal_id
  ] : null

  cluster_server_machine = try(data.azurerm_arc_machine.arc_machines[0], local.vm_host_virtual_machines[0], null)
  cluster_node_machine = try(
    slice(data.azurerm_arc_machine.arc_machines, 1, length(data.azurerm_arc_machine.arc_machines)),
    slice(local.vm_host_virtual_machines, 1, length(local.vm_host_virtual_machines)),
    null
  )
  cluster_node_machine_count = local.cluster_node_machine_count

  cluster_server_ip = try(coalesce(var.cluster_server_ip, local.vm_host_private_ips[0]), null)

  should_deploy_arc_machines            = local.should_use_arc_machines
  should_generate_cluster_server_token  = true
  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  custom_locations_oid                  = var.custom_locations_oid

  cluster_server_host_machine_username = var.cluster_server_host_machine_username
  key_vault                            = module.cloud_security_identity.key_vault
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

  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  aio_features                       = var.aio_features
  enable_opc_ua_simulator            = var.should_enable_opc_ua_simulator
  should_enable_akri_rest_connector  = var.should_enable_akri_rest_connector
  should_enable_akri_media_connector = var.should_enable_akri_media_connector
  should_enable_akri_onvif_connector = var.should_enable_akri_onvif_connector
  should_enable_akri_sse_connector   = var.should_enable_akri_sse_connector
  custom_akri_connectors             = var.custom_akri_connectors
  should_enable_otel_collector       = var.should_enable_otel_collector
}

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
