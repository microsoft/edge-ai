/**
 * # Dual Peered Single Node Cluster Blueprint
 *
 * This blueprint deploys two complete Azure IoT Operations environments with all cloud and edge components
 * for single-node cluster deployments with different address spaces and VNet peering between them.
 * Each cluster operates independently but can communicate through the peered virtual networks.
 */

locals {
  cluster_a_name = "cluster-a"
  cluster_b_name = "cluster-b"
}

// Cluster A - Primary cluster with first address space
module "cluster_a_cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "dual-peered-single-cluster"
    cluster   = local.cluster_a_name
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  // Optional parameters for using an existing resource group
  use_existing_resource_group = var.use_existing_resource_group_a
  resource_group_name         = var.resource_group_name_a
}

module "cluster_a_cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  aio_resource_group = module.cluster_a_cloud_resource_group.resource_group
}

module "cluster_a_cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  azmon_resource_group = module.cluster_a_cloud_resource_group.resource_group
}

module "cluster_a_cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  resource_group = module.cluster_a_cloud_resource_group.resource_group
}

module "cluster_a_cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  resource_group  = module.cluster_a_cloud_resource_group.resource_group
  aio_identity    = module.cluster_a_cloud_security_identity.aio_identity
  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  should_create_azure_functions = var.should_create_azure_functions
}

module "cluster_a_cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  resource_group         = module.cluster_a_cloud_resource_group.resource_group
  virtual_network_config = var.cluster_a_virtual_network_config
}

module "cluster_a_cloud_vm_host" {
  source = "../../../src/000-cloud/051-vm-host/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  resource_group          = module.cluster_a_cloud_resource_group.resource_group
  subnet_id               = module.cluster_a_cloud_networking.subnet_id
  arc_onboarding_identity = module.cluster_a_cloud_security_identity.arc_onboarding_identity
}

module "cluster_a_cloud_acr" {
  source = "../../../src/000-cloud/060-acr/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  location        = var.location
  instance        = var.instance

  resource_group = module.cluster_a_cloud_resource_group.resource_group

  network_security_group = module.cluster_a_cloud_networking.network_security_group
  virtual_network        = module.cluster_a_cloud_networking.virtual_network

  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
}

module "cluster_a_cloud_kubernetes" {
  source = "../../../src/000-cloud/070-kubernetes/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  location        = var.location
  instance        = var.instance

  resource_group = module.cluster_a_cloud_resource_group.resource_group

  network_security_group = module.cluster_a_cloud_networking.network_security_group
  virtual_network        = module.cluster_a_cloud_networking.virtual_network

  acr = module.cluster_a_cloud_acr.acr

  should_create_aks = var.should_create_aks
}

module "cluster_a_edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  resource_group          = module.cluster_a_cloud_resource_group.resource_group
  arc_onboarding_identity = module.cluster_a_cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp       = module.cluster_a_cloud_security_identity.arc_onboarding_sp
  cluster_server_machine  = module.cluster_a_cloud_vm_host.virtual_machines[0]

  should_deploy_arc_machines      = false
  should_get_custom_locations_oid = var.should_get_custom_locations_oid
  custom_locations_oid            = var.custom_locations_oid

  // Key Vault for script retrieval
  key_vault = module.cluster_a_cloud_security_identity.key_vault
}

module "cluster_a_edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.cluster_a_edge_cncf_cluster]

  adr_schema_registry   = module.cluster_a_cloud_data.schema_registry
  resource_group        = module.cluster_a_cloud_resource_group.resource_group
  aio_identity          = module.cluster_a_cloud_security_identity.aio_identity
  arc_connected_cluster = module.cluster_a_edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cluster_a_cloud_security_identity.key_vault
  secret_sync_identity  = module.cluster_a_cloud_security_identity.secret_sync_identity

  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  aio_features            = var.aio_features
  enable_opc_ua_simulator = var.should_enable_opc_ua_simulator
}

module "cluster_a_edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.cluster_a_edge_iot_ops]

  location           = var.location
  resource_group     = module.cluster_a_cloud_resource_group.resource_group
  custom_location_id = module.cluster_a_edge_iot_ops.custom_location_id

  should_create_default_asset = var.should_enable_opc_ua_simulator
  asset_endpoint_profiles     = var.asset_endpoint_profiles
  assets                      = var.assets
}

module "cluster_a_edge_observability" {
  source = "../../../src/100-edge/120-observability/terraform"

  depends_on = [module.cluster_a_edge_iot_ops]

  aio_azure_managed_grafana        = module.cluster_a_cloud_observability.azure_managed_grafana
  aio_azure_monitor_workspace      = module.cluster_a_cloud_observability.azure_monitor_workspace
  aio_log_analytics_workspace      = module.cluster_a_cloud_observability.log_analytics_workspace
  aio_logs_data_collection_rule    = module.cluster_a_cloud_observability.logs_data_collection_rule
  aio_metrics_data_collection_rule = module.cluster_a_cloud_observability.metrics_data_collection_rule
  resource_group                   = module.cluster_a_cloud_resource_group.resource_group
  arc_connected_cluster            = module.cluster_a_edge_cncf_cluster.arc_connected_cluster
}

module "cluster_a_edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  depends_on = [module.cluster_a_edge_iot_ops]

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_a_name}"
  instance        = var.instance

  aio_custom_locations = module.cluster_a_edge_iot_ops.custom_locations
  aio_dataflow_profile = module.cluster_a_edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.cluster_a_edge_iot_ops.aio_instance
  aio_identity         = module.cluster_a_cloud_security_identity.aio_identity
  event_grid           = module.cluster_a_cloud_messaging.event_grid
  event_hub            = module.cluster_a_cloud_messaging.event_hub
}

// Cluster B - Secondary cluster with second address space
module "cluster_b_cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "dual-peered-single-cluster"
    cluster   = local.cluster_b_name
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  // Optional parameters for using an existing resource group
  use_existing_resource_group = var.use_existing_resource_group_b
  resource_group_name         = var.resource_group_name_b
}

module "cluster_b_cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  aio_resource_group = module.cluster_b_cloud_resource_group.resource_group
}

module "cluster_b_cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  azmon_resource_group = module.cluster_b_cloud_resource_group.resource_group
}

module "cluster_b_cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  resource_group = module.cluster_b_cloud_resource_group.resource_group
}

module "cluster_b_cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  resource_group  = module.cluster_b_cloud_resource_group.resource_group
  aio_identity    = module.cluster_b_cloud_security_identity.aio_identity
  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  should_create_azure_functions = var.should_create_azure_functions
}

module "cluster_b_cloud_networking" {
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  resource_group         = module.cluster_b_cloud_resource_group.resource_group
  virtual_network_config = var.cluster_b_virtual_network_config
}

module "cluster_b_cloud_vm_host" {
  source = "../../../src/000-cloud/051-vm-host/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  resource_group          = module.cluster_b_cloud_resource_group.resource_group
  subnet_id               = module.cluster_b_cloud_networking.subnet_id
  arc_onboarding_identity = module.cluster_b_cloud_security_identity.arc_onboarding_identity
}

module "cluster_b_cloud_acr" {
  source = "../../../src/000-cloud/060-acr/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  location        = var.location
  instance        = var.instance

  resource_group = module.cluster_b_cloud_resource_group.resource_group

  network_security_group = module.cluster_b_cloud_networking.network_security_group
  virtual_network        = module.cluster_b_cloud_networking.virtual_network

  should_create_acr_private_endpoint = var.should_create_acr_private_endpoint
}

module "cluster_b_cloud_kubernetes" {
  source = "../../../src/000-cloud/070-kubernetes/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  location        = var.location
  instance        = var.instance

  resource_group = module.cluster_b_cloud_resource_group.resource_group

  network_security_group = module.cluster_b_cloud_networking.network_security_group
  virtual_network        = module.cluster_b_cloud_networking.virtual_network

  acr = module.cluster_b_cloud_acr.acr

  should_create_aks = var.should_create_aks
}

module "cluster_b_edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  resource_group          = module.cluster_b_cloud_resource_group.resource_group
  arc_onboarding_identity = module.cluster_b_cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp       = module.cluster_b_cloud_security_identity.arc_onboarding_sp
  cluster_server_machine  = module.cluster_b_cloud_vm_host.virtual_machines[0]

  should_deploy_arc_machines      = false
  should_get_custom_locations_oid = var.should_get_custom_locations_oid
  custom_locations_oid            = var.custom_locations_oid

  // Key Vault for script retrieval
  key_vault = module.cluster_b_cloud_security_identity.key_vault
}

module "cluster_b_edge_iot_ops" {
  source = "../../../src/100-edge/110-iot-ops/terraform"

  depends_on = [module.cluster_b_edge_cncf_cluster]

  adr_schema_registry   = module.cluster_b_cloud_data.schema_registry
  resource_group        = module.cluster_b_cloud_resource_group.resource_group
  aio_identity          = module.cluster_b_cloud_security_identity.aio_identity
  arc_connected_cluster = module.cluster_b_edge_cncf_cluster.arc_connected_cluster
  secret_sync_key_vault = module.cluster_b_cloud_security_identity.key_vault
  secret_sync_identity  = module.cluster_b_cloud_security_identity.secret_sync_identity

  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener

  aio_features            = var.aio_features
  enable_opc_ua_simulator = var.should_enable_opc_ua_simulator
}

module "cluster_b_edge_assets" {
  source = "../../../src/100-edge/111-assets/terraform"

  depends_on = [module.cluster_b_edge_iot_ops]

  location           = var.location
  resource_group     = module.cluster_b_cloud_resource_group.resource_group
  custom_location_id = module.cluster_b_edge_iot_ops.custom_location_id

  should_create_default_asset = var.should_enable_opc_ua_simulator
  asset_endpoint_profiles     = var.asset_endpoint_profiles
  assets                      = var.assets
}

module "cluster_b_edge_observability" {
  source = "../../../src/100-edge/120-observability/terraform"

  depends_on = [module.cluster_b_edge_iot_ops]

  aio_azure_managed_grafana        = module.cluster_b_cloud_observability.azure_managed_grafana
  aio_azure_monitor_workspace      = module.cluster_b_cloud_observability.azure_monitor_workspace
  aio_log_analytics_workspace      = module.cluster_b_cloud_observability.log_analytics_workspace
  aio_logs_data_collection_rule    = module.cluster_b_cloud_observability.logs_data_collection_rule
  aio_metrics_data_collection_rule = module.cluster_b_cloud_observability.metrics_data_collection_rule
  resource_group                   = module.cluster_b_cloud_resource_group.resource_group
  arc_connected_cluster            = module.cluster_b_edge_cncf_cluster.arc_connected_cluster
}

module "cluster_b_edge_messaging" {
  source = "../../../src/100-edge/130-messaging/terraform"

  depends_on = [module.cluster_b_edge_iot_ops]

  environment     = var.environment
  resource_prefix = "${var.resource_prefix}-${local.cluster_b_name}"
  instance        = var.instance

  aio_custom_locations = module.cluster_b_edge_iot_ops.custom_locations
  aio_dataflow_profile = module.cluster_b_edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.cluster_b_edge_iot_ops.aio_instance
  aio_identity         = module.cluster_b_cloud_security_identity.aio_identity
  event_grid           = module.cluster_b_cloud_messaging.event_grid
  event_hub            = module.cluster_b_cloud_messaging.event_hub
}

// VNet Peering between Cluster A and Cluster B
resource "azurerm_virtual_network_peering" "cluster_a_to_cluster_b" {
  name                      = "peer-${local.cluster_a_name}-to-${local.cluster_b_name}"
  resource_group_name       = module.cluster_a_cloud_resource_group.resource_group.name
  virtual_network_name      = module.cluster_a_cloud_networking.virtual_network.name
  remote_virtual_network_id = module.cluster_b_cloud_networking.virtual_network.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "cluster_b_to_cluster_a" {
  name                      = "peer-${local.cluster_b_name}-to-${local.cluster_a_name}"
  resource_group_name       = module.cluster_b_cloud_resource_group.resource_group.name
  virtual_network_name      = module.cluster_b_cloud_networking.virtual_network.name
  remote_virtual_network_id = module.cluster_a_cloud_networking.virtual_network.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

// Certificate Generation Module (Step CLI)
module "certificate_generation" {
  count  = var.should_create_certificates && !var.use_terraform_certificates ? 1 : 0
  source = "./modules/certificate-generation"

  server_vm_private_ip   = module.cluster_a_cloud_vm_host.virtual_machines[0].private_ip_address
  certs_script_path      = "${path.module}/../scripts/certs.sh"
  certs_output_directory = "${path.module}/../certs"

  depends_on = [
    module.cluster_a_cloud_vm_host,
    module.cluster_b_cloud_vm_host
  ]
}

// Terraform Certificate Generation Module (Pure Terraform)
module "terraform_certificate_generation" {
  count  = var.should_create_certificates && var.use_terraform_certificates ? 1 : 0
  source = "./modules/terraform-certificate-generation"

  server_vm_private_ip   = module.cluster_a_cloud_vm_host.virtual_machines[0].private_ip_address
  certs_output_directory = "${path.module}/../certs"

  depends_on = [
    module.cluster_a_cloud_vm_host,
    module.cluster_b_cloud_vm_host
  ]
}

// Secret Provider Class Module (when certificates are not generated)
module "secret_provider_class" {
  count  = var.should_create_certificates ? 0 : 1
  source = "./modules/secret-provider-class"

  cluster_a_name                 = local.cluster_a_name
  cluster_a_location             = var.location
  cluster_a_resource_group       = module.cluster_a_cloud_resource_group.resource_group
  cluster_a_custom_location_id   = module.cluster_a_edge_iot_ops.custom_location_id
  cluster_a_key_vault            = module.cluster_a_cloud_security_identity.key_vault
  cluster_a_secret_sync_identity = module.cluster_a_cloud_security_identity.secret_sync_identity

  cluster_b_name                 = local.cluster_b_name
  cluster_b_location             = var.location
  cluster_b_resource_group       = module.cluster_b_cloud_resource_group.resource_group
  cluster_b_custom_location_id   = module.cluster_b_edge_iot_ops.custom_location_id
  cluster_b_key_vault            = module.cluster_b_cloud_security_identity.key_vault
  cluster_b_secret_sync_identity = module.cluster_b_cloud_security_identity.secret_sync_identity

  depends_on = [
    module.cluster_a_edge_iot_ops,
    module.cluster_b_edge_iot_ops
  ]
}

// Custom Script Deployment Module
module "custom_script_deployment" {
  source = "./modules/custom-script-deployment"

  should_deploy_server_central_script    = var.should_deploy_server_central_script || var.should_deploy_custom_scripts
  should_deploy_client_technology_script = var.should_deploy_client_technology_script || var.should_deploy_custom_scripts

  server_vm_id = module.cluster_a_cloud_vm_host.virtual_machines[0].id
  client_vm_id = module.cluster_b_cloud_vm_host.virtual_machines[0].id

  depends_on = [
    module.cluster_a_edge_iot_ops,
    module.cluster_b_edge_iot_ops,
    module.certificate_generation,
    module.terraform_certificate_generation,
    module.secret_provider_class
  ]
}
