/**
 * # Azure IoT Operations Module
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.
 *
 */

data "azurerm_subscription" "current" {}

locals {
  resource_group_id        = "${data.azurerm_subscription.current.id}/resourceGroups/${var.resource_group_name}"
  arc_connected_cluster_id = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/${var.connected_cluster_name}"
  is_customer_managed      = var.trust_config.source == "CustomerManaged"

  # Hard-coding the values for CustomerManaged trust resources
  customer_managed_trust_settings = {
    issuerName    = "issuer-custom-root-ca-cert"
    issuerKind    = "ClusterIssuer"
    configMapName = "bundle-custom-ca-cert"
    configMapKey  = "ca.crt"
  }
}

module "aio_init" {
  source = "./modules/aio_init"

  arc_connected_cluster_id = local.arc_connected_cluster_id
  aio_platform_config      = var.aio_platform_config
  platform                 = var.platform
  open_service_mesh        = var.open_service_mesh
  edge_storage_accelerator = var.edge_storage_accelerator
  secret_sync_controller   = var.secret_sync_controller
}

module "aio_customer_managed_trust" {
  source     = "./modules/aio_customer_managed_trust"
  depends_on = [module.aio_init]
  count      = local.is_customer_managed ? 1 : 0

  resource_group_name             = var.resource_group_name
  connected_cluster_name          = var.connected_cluster_name
  aio_root_ca                     = var.aio_root_ca
  key_vault_name                  = var.key_vault_name
  sse_user_managed_identity_name  = var.sse_user_managed_identity_name
  customer_managed_trust_settings = local.customer_managed_trust_settings
  aio_namespace                   = var.operations_config.namespace
  resource_group_id               = local.resource_group_id
}

module "aio_instance" {
  source     = "./modules/aio_instance"
  depends_on = [module.aio_customer_managed_trust]

  connected_cluster_location        = var.connected_cluster_location
  connected_cluster_name            = var.connected_cluster_name
  trust_config                      = var.trust_config
  operations_config                 = var.operations_config
  schema_registry_id                = var.schema_registry_id
  mqtt_broker_config                = var.mqtt_broker_config
  metrics                           = var.metrics
  dataflow_instance_count           = var.dataflow_instance_count
  deploy_resource_sync_rules        = var.deploy_resource_sync_rules
  customer_managed_trust_settings   = local.customer_managed_trust_settings
  secret_store_cluster_extension_id = module.aio_init.secret_store_extension_cluster_id
  platform_cluster_extension_id     = module.aio_init.platform_cluster_extension_id
  resource_group_id                 = local.resource_group_id
  arc_connected_cluster_id          = local.arc_connected_cluster_id
}

module "aio_post_install" {
  source     = "./modules/aio_post_install"
  depends_on = [module.aio_instance]
  count      = var.enable_instance_secret_sync ? 1 : 0

  connected_cluster_location     = var.connected_cluster_location
  resource_group_name            = var.resource_group_name
  connected_cluster_name         = var.connected_cluster_name
  key_vault_name                 = var.key_vault_name
  sse_user_managed_identity_name = var.sse_user_managed_identity_name
  is_sse_standalone_enabled      = local.is_customer_managed ? true : false
  instance_name                  = module.aio_instance.instance_name
  resource_group_id              = local.resource_group_id
  custom_location_id             = module.aio_instance.custom_location_id
  aio_namespace                  = var.operations_config.namespace
}
