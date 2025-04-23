module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  tags = {
    blueprint = "full-single-cluster"
  }
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
}

module "cloud_security_identity" {
  source = "../../../src/000-cloud/010-security-identity/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  aio_resource_group = module.cloud_resource_group.resource_group
}

module "cloud_observability" {
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location

  azmon_resource_group = module.cloud_resource_group.resource_group
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  resource_group = module.cloud_resource_group.resource_group
}

module "cloud_fabric" {
  source = "../../../src/000-cloud/031-fabric/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix

  resource_group                   = module.cloud_resource_group.resource_group
  should_create_fabric_capacity    = var.should_create_fabric
  should_create_fabric_eventstream = var.should_create_fabric
  should_create_fabric_lakehouse   = var.should_create_fabric
  should_create_fabric_workspace   = var.should_create_fabric
  // eventhub_endpoint = module.cloud_messaging.event_hub. fill_in
}

module "cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  resource_group  = module.cloud_resource_group.resource_group
  aio_identity    = module.cloud_security_identity.aio_identity
  environment     = var.environment
  resource_prefix = var.resource_prefix
}

module "cloud_vm_host" {
  source = "../../../src/000-cloud/050-vm-host/terraform"

  environment        = var.environment
  location           = var.location
  resource_prefix    = var.resource_prefix
  host_machine_count = var.host_machine_count

  resource_group          = module.cloud_resource_group.resource_group
  arc_onboarding_identity = module.cloud_security_identity.arc_onboarding_identity
}

module "cloud_aks_acr" {
  source = "../../../src/000-cloud/060-aks-acr/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location

  resource_group = module.cloud_resource_group.resource_group

  network_security_group = module.cloud_vm_host.network_security_group
  virtual_network        = module.cloud_vm_host.virtual_network
}

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix

  resource_group                 = module.cloud_resource_group.resource_group
  arc_onboarding_identity        = module.cloud_security_identity.arc_onboarding_identity
  arc_onboarding_sp              = module.cloud_security_identity.arc_onboarding_sp
  cluster_server_virtual_machine = module.cloud_vm_host.virtual_machines[0]
  cluster_node_virtual_machines  = slice(module.cloud_vm_host.virtual_machines, 1, length(module.cloud_vm_host.virtual_machines))

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
}

module "edge_observability" {
  source = "../../../src/100-edge/120-observability/terraform"

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

  environment     = var.environment
  resource_prefix = var.resource_prefix

  aio_custom_locations = module.edge_iot_ops.custom_locations
  aio_dataflow_profile = module.edge_iot_ops.aio_dataflow_profile
  aio_instance         = module.edge_iot_ops.aio_instance
  aio_identity         = module.cloud_security_identity.aio_identity
}
