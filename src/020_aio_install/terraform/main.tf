data "azurerm_subscription" "current" {}

locals {
  # Matching the naming convention from /cluster_install
  resource_group_name    = coalesce(var.existing_resource_group_name, "${var.resource_prefix}-aio-edge-rg")
  connected_cluster_name = coalesce(var.existing_connected_cluster_name, "${var.resource_prefix}-arc")
  # Hard-coding the values for CustomerManagedGenerateIssuer trust resources, these values are not configurable
  resource_group = {
    id   = "${data.azurerm_subscription.current.id}/resourceGroups/${local.resource_group_name}"
    name = local.resource_group_name
  }
  customer_managed_trust_settings = coalesce(var.byo_issuer_trust_settings, {
    issuer_name    = "issuer-custom-root-ca-cert"
    issuer_kind    = "ClusterIssuer" # This needs to be set as ClusterIssuer when using CustomerManagedGenerateIssuer, since current implementation does not support Issuer kind. Validate if adapt in future.
    configmap_name = "bundle-custom-ca-cert"
    configmap_key  = "ca.crt"
  })
}

module "schema_registry" {
  source = "./modules/schema_registry"

  location            = var.location
  resource_group_name = local.resource_group.name
  resource_prefix     = var.resource_prefix
}

module "sse_key_vault" {
  source = "./modules/sse_key_vault"

  location                = var.location
  resource_group_name     = local.resource_group.name
  resource_prefix         = var.resource_prefix
  existing_key_vault_name = var.existing_key_vault_name
}

locals {
  is_customer_managed_generate_issuer = var.trust_config_source == "CustomerManagedGenerateIssuer"

  aio_ca = try(module.generate_aio_ca[0].aio_ca, var.aio_ca)
}

module "generate_aio_ca" {
  source = "./modules/generate_aio_ca"
  count  = local.is_customer_managed_generate_issuer && var.aio_ca == null ? 1 : 0
}

module "aio" {
  source = "./modules/azure_iot_operations"

  connected_cluster_location      = var.location
  resource_group                  = local.resource_group
  connected_cluster_name          = local.connected_cluster_name
  schema_registry_id              = module.schema_registry.registry_id
  trust_config_source             = var.trust_config_source
  key_vault                       = module.sse_key_vault.key_vault
  sse_user_managed_identity       = module.sse_key_vault.sse_user_managed_identity
  aio_ca                          = local.aio_ca
  enable_instance_secret_sync     = var.enable_aio_instance_secret_sync
  aio_platform_config             = var.aio_platform_config
  customer_managed_trust_settings = local.customer_managed_trust_settings
  enable_otel_collector           = var.enable_otel_collector
}

module "event_hubs" {
  source = "./modules/event_hubs"

  connected_cluster_name = local.connected_cluster_name
  resource_prefix        = var.resource_prefix
  resource_group_name    = local.resource_group.name
  aio_extension_name     = module.aio.aio_extension_name
  depends_on             = [module.aio]
  count                  = var.enable_event_hubs ? 1 : 0
}

module "opc_ua_simulator" {
  source = "./modules/opc_ua_simulator"

  location               = var.location
  resource_group         = local.resource_group
  connected_cluster_name = local.connected_cluster_name
  custom_location_id     = module.aio.custom_location_id
  depends_on             = [module.aio]

  count = var.enable_opc_ua_simulator ? 1 : 0
}

module "sample_data_flow" {
  source = "./modules/sample_data_flow"

  resource_prefix     = var.resource_prefix
  resource_group_name = local.resource_group.name
  custom_location_id  = module.aio.custom_location_id
  aio_instance_name   = module.aio.aio_instance_name
  event_hub           = module.event_hubs[0].event_hub
  asset_name          = module.opc_ua_simulator[0].asset_name
  depends_on          = [module.event_hubs]

  count = var.enable_sample_dataflow_to_event_hub ? 1 : 0
}