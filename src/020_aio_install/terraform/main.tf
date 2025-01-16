locals {
  # Matching the naming convention from /cluster_install
  resource_group_name    = coalesce(var.resource_group_name, "${var.resource_prefix}-aio-edge-rg")
  connected_cluster_name = coalesce(var.connected_cluster_name, "${var.resource_prefix}-arc")
}

module "schema_registry" {
  source              = "./modules/schema_registry"
  location            = var.location
  resource_group_name = local.resource_group_name
  resource_prefix     = var.resource_prefix
}

module "aio_key_vault" {
  source              = "./modules/key_vault"
  location            = var.location
  resource_group_name = local.resource_group_name
  resource_prefix     = var.resource_prefix
}

locals {
  is_customer_managed = var.trust_config.source == "CustomerManaged"

  aio_ca = try(module.generate_aio_ca[0].aio_ca, var.aio_ca)
}

module "generate_aio_ca" {
  source = "./modules/generate_aio_ca"
  count  = local.is_customer_managed && var.aio_ca == null ? 1 : 0
}

module "aio" {
  source                         = "./modules/azure_iot_operations"
  resource_group_name            = local.resource_group_name
  connected_cluster_location     = var.location
  connected_cluster_name         = local.connected_cluster_name
  schema_registry_id             = module.schema_registry.registry_id
  trust_config                   = var.trust_config
  key_vault_name                 = module.aio_key_vault.name
  sse_user_managed_identity_name = module.aio_key_vault.sse_user_managed_identity_name
  aio_ca                         = local.aio_ca
  enable_instance_secret_sync    = var.enable_aio_instance_secret_sync
}
