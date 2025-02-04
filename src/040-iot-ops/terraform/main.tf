/**
 * # Azure IoT Operations
 *
 * Sets up Azure IoT Operations in a connected cluster and includes
 * an resources or configuration that must be created before an IoT Operations
 * Instance can be created, and after.
 */

locals {
  # Hard-coding the values for CustomerManagedGenerateIssuer trust resources, these values are not configurable
  customer_managed_trust_settings = coalesce(var.byo_issuer_trust_settings, {
    issuer_name    = "issuer-custom-root-ca-cert"
    issuer_kind    = "ClusterIssuer" # This needs to be set as ClusterIssuer when using CustomerManagedGenerateIssuer, since current implementation does not support Issuer kind. Validate if adapt in future.
    configmap_name = "bundle-custom-ca-cert"
    configmap_key  = "ca.crt"
  })

  is_customer_managed_generate_issuer = var.trust_config_source == "CustomerManagedGenerateIssuer"
  is_customer_managed_byo_issuer      = var.trust_config_source == "CustomerManagedByoIssuer"

  trust_source           = (local.is_customer_managed_generate_issuer || local.is_customer_managed_byo_issuer) ? "CustomerManaged" : "SelfSigned"
  should_generate_aio_ca = local.is_customer_managed_generate_issuer && var.aio_ca == null
  aio_ca                 = try(module.customer_managed_self_signed_ca[0].aio_ca, var.aio_ca)

  scripts_otel_collector = !var.enable_otel_collector ? [] : [{
    files : ["apply-otel-collector.sh"]
    environment : {}
  }]

}

module "customer_managed_self_signed_ca" {
  count = local.should_generate_aio_ca ? 1 : 0

  source = "./modules/self-signed-ca"
}

###
# `az iot ops init`
###

module "iot_ops_init" {
  source = "./modules/iot-ops-init"

  arc_connected_cluster_id = var.arc_connected_cluster.id
  aio_platform_config      = var.aio_platform_config
  platform                 = var.platform
  open_service_mesh        = var.open_service_mesh
  edge_storage_accelerator = var.edge_storage_accelerator
  secret_sync_controller   = var.secret_sync_controller
}

###
# Post `az iot ops init`
###

module "customer_managed_trust_issuer" {
  source     = "./modules/customer-managed-trust-issuer"
  depends_on = [module.iot_ops_init]
  count      = local.is_customer_managed_generate_issuer ? 1 : 0

  resource_group                  = var.aio_resource_group
  connected_cluster_name          = var.arc_connected_cluster.name
  aio_ca                          = local.aio_ca
  key_vault                       = var.sse_key_vault
  sse_user_managed_identity       = var.sse_user_assigned_identity
  customer_managed_trust_settings = local.customer_managed_trust_settings
}

module "apply_scripts_post_init" {
  source = "./modules/apply-scripts"
  count = anytrue([
    local.is_customer_managed_generate_issuer,
    var.enable_otel_collector,
  ]) ? 1 : 0

  depends_on = [
    module.iot_ops_init,
    module.customer_managed_trust_issuer
  ]

  scripts = flatten([
    try([module.customer_managed_trust_issuer[0].scripts], []),
    local.scripts_otel_collector,
  ])

  aio_namespace          = var.operations_config.namespace
  connected_cluster_name = var.arc_connected_cluster.name
  resource_group_name    = var.aio_resource_group.name
}

###
# `iot ops create`
###

module "iot_ops_instance" {
  source     = "./modules/iot-ops-instance"
  depends_on = [module.apply_scripts_post_init]

  resource_group_id                 = var.aio_resource_group.id
  arc_connected_cluster_id          = var.arc_connected_cluster.id
  connected_cluster_location        = var.arc_connected_cluster.location
  connected_cluster_name            = var.arc_connected_cluster.name
  trust_source                      = local.trust_source
  operations_config                 = var.operations_config
  schema_registry_id                = var.adr_schema_registry.id
  mqtt_broker_config                = var.mqtt_broker_config
  dataflow_instance_count           = var.dataflow_instance_count
  deploy_resource_sync_rules        = var.deploy_resource_sync_rules
  customer_managed_trust_settings   = local.customer_managed_trust_settings
  secret_store_cluster_extension_id = module.iot_ops_init.secret_store_extension_cluster_id
  platform_cluster_extension_id     = module.iot_ops_init.platform_cluster_extension_id
  enable_otel_collector             = var.enable_otel_collector
  aio_uami_id                       = var.aio_user_assigned_identity.id
}

###
# Post `iot ops create`
###

module "iot_ops_instance_post" {
  source     = "./modules/iot-ops-instance-post"
  depends_on = [module.iot_ops_instance]

  resource_group               = var.aio_resource_group
  connected_cluster_location   = var.arc_connected_cluster.location
  connected_cluster_name       = var.arc_connected_cluster.name
  key_vault                    = var.sse_key_vault
  enable_instance_secret_sync  = var.enable_instance_secret_sync
  custom_location_id           = module.iot_ops_instance.custom_location_id
  aio_namespace                = var.operations_config.namespace
  sse_user_managed_identity    = var.sse_user_assigned_identity
  aio_user_managed_identity_id = var.aio_user_assigned_identity.id
}

module "opc_ua_simulator" {
  count = var.enable_opc_ua_simulator ? 1 : 0

  source = "./modules/opc-ua-simulator"

  depends_on = [module.iot_ops_instance_post]

  location               = var.aio_resource_group.location
  resource_group         = var.aio_resource_group
  connected_cluster_name = var.arc_connected_cluster.name
  custom_location_id     = module.iot_ops_instance.custom_location_id
}
