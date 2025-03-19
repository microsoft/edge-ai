module "onboard_requirements" {
  source = "../../../src/005-onboard-reqs/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance
}

module "vm_host" {
  source = "../../../src/010-vm-host/terraform"

  resource_prefix                       = var.resource_prefix
  environment                           = var.environment
  instance                              = var.instance
  location                              = var.location
  aio_resource_group                    = module.onboard_requirements.resource_group
  arc_onboarding_user_assigned_identity = module.onboard_requirements.arc_onboarding_user_assigned_identity
  vm_count                              = var.host_machine_count
}

module "cncf_cluster_install" {
  source = "../../../src/020-cncf-cluster/terraform"

  environment                          = var.environment
  instance                             = var.instance
  resource_prefix                      = var.resource_prefix
  aio_resource_group                   = module.onboard_requirements.resource_group
  cluster_server_virtual_machine       = module.vm_host.virtual_machines[0]
  cluster_node_virtual_machines        = slice(module.vm_host.virtual_machines, 1, length(module.vm_host.virtual_machines))
  should_generate_cluster_server_token = true
  cluster_server_ip                    = module.vm_host.private_ips[0]
  custom_locations_oid                 = var.custom_locations_oid
  should_get_custom_locations_oid      = var.should_get_custom_locations_oid
}

module "iot_ops_cloud_requirements" {
  source = "../../../src/030-iot-ops-cloud-reqs/terraform"

  resource_prefix    = var.resource_prefix
  environment        = var.environment
  instance           = var.instance
  aio_resource_group = module.onboard_requirements.resource_group
}

module "iot_ops_install" {
  source = "../../../src/040-iot-ops/terraform"

  aio_resource_group         = module.onboard_requirements.resource_group
  arc_connected_cluster      = module.cncf_cluster_install.arc_connected_cluster
  adr_schema_registry        = module.iot_ops_cloud_requirements.adr_schema_registry
  aio_user_assigned_identity = module.iot_ops_cloud_requirements.aio_user_assigned_identity
  sse_key_vault              = module.iot_ops_cloud_requirements.sse_key_vault
  sse_user_assigned_identity = module.iot_ops_cloud_requirements.sse_user_assigned_identity
}

module "messaging" {
  source = "../../../src/050-messaging/terraform"

  resource_prefix            = var.resource_prefix
  environment                = var.environment
  instance                   = var.instance
  aio_resource_group         = module.onboard_requirements.resource_group
  aio_user_assigned_identity = module.iot_ops_cloud_requirements.aio_user_assigned_identity
  aio_custom_locations       = module.iot_ops_install.custom_locations
  aio_instance               = module.iot_ops_install.aio_instance
  aio_dataflow_profile       = module.iot_ops_install.aio_dataflow_profile
}

module "observability" {
  source = "../../../src/070-observability/terraform"

  environment          = var.environment
  resource_prefix      = var.resource_prefix
  instance             = var.instance
  azmon_resource_group = module.onboard_requirements.resource_group
}

module "iot_ops_utilities" {
  source = "../../../src/080-iot-ops-utility/terraform"

  aio_resource_group               = module.onboard_requirements.resource_group
  arc_connected_cluster            = module.cncf_cluster_install.arc_connected_cluster
  aio_azure_monitor_workspace      = module.observability.azure_monitor_workspace
  aio_log_analytics_workspace      = module.observability.log_analytics_workspace
  aio_azure_managed_grafana        = module.observability.azure_managed_grafana
  aio_logs_data_collection_rule    = module.observability.logs_data_collection_rule
  aio_metrics_data_collection_rule = module.observability.metrics_data_collection_rule
}
