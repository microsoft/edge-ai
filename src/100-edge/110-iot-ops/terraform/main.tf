/**
 * # Azure IoT Operations
 *
 * Sets up Azure IoT Operations in a connected cluster and includes
 * an resources or configuration that must be created before an IoT Operations
 * Instance can be created, and after.
 */

locals {
  // Hard-coding the values for CustomerManagedGenerateIssuer trust resources, these values are not configurable
  customer_managed_trust_settings = coalesce(var.byo_issuer_trust_settings, {
    issuer_name = "issuer-custom-root-ca-cert"
    issuer_kind = "ClusterIssuer"
    // This needs to be set as ClusterIssuer when using CustomerManagedGenerateIssuer, since current implementation does not support Issuer kind. Validate if adapt in future.
    configmap_name = "bundle-custom-ca-cert"
    configmap_key  = "ca.crt"
  })

  is_customer_managed_generate_issuer = var.trust_config_source == "CustomerManagedGenerateIssuer"
  is_customer_managed_byo_issuer      = var.trust_config_source == "CustomerManagedByoIssuer"

  trust_source           = (local.is_customer_managed_generate_issuer || local.is_customer_managed_byo_issuer) ? "CustomerManaged" : "SelfSigned"
  should_generate_aio_ca = local.is_customer_managed_generate_issuer && var.aio_ca == null
  aio_ca                 = try(module.customer_managed_self_signed_ca[0].aio_ca, var.aio_ca)

  scripts_otel_collector = !var.should_enable_otel_collector ? [] : [
    {
      files : ["apply-otel-collector.sh"]
      environment : {}
    }
  ]

}

/*
 * Certificate Trust
 */

module "customer_managed_self_signed_ca" {
  count = local.should_generate_aio_ca ? 1 : 0

  source = "./modules/self-signed-ca"
}

/*
 * Role Assignment
 */

module "role_assignments" {
  count = var.should_assign_key_vault_roles ? 1 : 0

  source = "./modules/role-assignment"

  secret_sync_identity  = var.secret_sync_identity
  secret_sync_key_vault = var.secret_sync_key_vault
}

/*
 * IoT Ops Init
 */

module "iot_ops_init" {
  source = "./modules/iot-ops-init"

  depends_on = [module.role_assignments]

  arc_connected_cluster_id     = var.arc_connected_cluster.id
  aio_platform_config          = var.aio_platform_config
  platform                     = var.platform
  edge_storage_accelerator     = var.edge_storage_accelerator
  secret_sync_controller       = var.secret_sync_controller
  resource_group               = var.resource_group
  connected_cluster_name       = var.arc_connected_cluster.name
  secret_sync_identity         = var.secret_sync_identity
  enable_instance_secret_sync  = var.enable_instance_secret_sync
  aio_namespace                = var.operations_config.namespace
  aio_user_managed_identity_id = var.aio_identity.id
}

module "customer_managed_trust_issuer" {
  source     = "./modules/customer-managed-trust-issuer"
  depends_on = [module.iot_ops_init]
  count      = local.is_customer_managed_generate_issuer ? 1 : 0

  resource_group                  = var.resource_group
  connected_cluster_name          = var.arc_connected_cluster.name
  aio_ca                          = local.aio_ca
  key_vault                       = var.secret_sync_key_vault
  sse_user_managed_identity       = var.secret_sync_identity
  customer_managed_trust_settings = local.customer_managed_trust_settings
}

module "apply_scripts_post_init" {
  source = "./modules/apply-scripts"
  count = anytrue([
    local.is_customer_managed_generate_issuer,
    var.should_enable_otel_collector,
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
  resource_group_name    = var.resource_group.name
}

/*
 * IoT Ops Create
 */

module "iot_ops_instance" {
  source     = "./modules/iot-ops-instance"
  depends_on = [module.apply_scripts_post_init]

  resource_group                          = var.resource_group
  key_vault                               = var.secret_sync_key_vault
  enable_instance_secret_sync             = var.enable_instance_secret_sync
  secret_sync_identity                    = var.secret_sync_identity
  mqtt_broker_persistence_config          = var.mqtt_broker_persistence_config
  arc_connected_cluster_id                = var.arc_connected_cluster.id
  connected_cluster_location              = var.arc_connected_cluster.location
  connected_cluster_name                  = var.arc_connected_cluster.name
  trust_source                            = local.trust_source
  operations_config                       = var.operations_config
  schema_registry_id                      = var.adr_schema_registry.id
  adr_namespace_id                        = try(var.adr_namespace.id, null)
  mqtt_broker_config                      = var.mqtt_broker_config
  dataflow_instance_count                 = var.dataflow_instance_count
  should_deploy_resource_sync_rules       = var.should_deploy_resource_sync_rules
  customer_managed_trust_settings         = local.customer_managed_trust_settings
  secret_store_cluster_extension_id       = module.iot_ops_init.secret_store_extension_cluster_id
  platform_cluster_extension_id           = module.iot_ops_init.platform_cluster_extension_id
  should_enable_otel_collector            = var.should_enable_otel_collector
  aio_uami_id                             = var.aio_identity.id
  aio_features                            = var.aio_features
  should_create_anonymous_broker_listener = var.should_create_anonymous_broker_listener
  broker_listener_anonymous_config        = var.broker_listener_anonymous_config
}

/*
 * OPC UA Simulator
 */

module "opc_ua_simulator" {
  count = var.enable_opc_ua_simulator ? 1 : 0

  source = "./modules/opc-ua-simulator"

  depends_on = [module.iot_ops_instance]

  resource_group         = var.resource_group
  connected_cluster_name = var.arc_connected_cluster.name
}

/*
 * Akri REST HTTP Connector
 */

module "akri_rest_connector" {
  count = var.should_enable_akri_rest_connector ? 1 : 0

  source = "./modules/akri-rest-connector"

  depends_on = [module.iot_ops_instance]

  # Required inputs
  aio_instance_id    = module.iot_ops_instance.aio_instance.id
  custom_location_id = module.iot_ops_instance.custom_locations.id

  # Common variables (derived from available resources)
  environment     = "prod" # Default since not available in parent
  resource_prefix = "aio"  # Default since not available in parent
  location        = var.resource_group.location

  # Connector configuration (pass the entire config object)
  akri_rest_connector_config = var.akri_rest_connector_config
}
