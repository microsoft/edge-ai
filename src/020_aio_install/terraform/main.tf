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

  aio_root_ca = {
    cert_pem        = try(tls_self_signed_cert.ca[0].cert_pem, var.aio_root_ca.cert_pem, "")
    private_key_pem = try(tls_private_key.ca[0].private_key_pem, var.aio_root_ca.private_key_pem, "")
  }
}

resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  count       = local.is_customer_managed && var.aio_root_ca == null ? 1 : 0
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca[0].private_key_pem
  validity_period_hours = 8076
  allowed_uses          = ["cert_signing"]
  is_ca_certificate     = true
  set_authority_key_id  = true
  set_subject_key_id    = true
  subject {
    common_name = "AIO Root CA - Self Signed"
  }
  count = local.is_customer_managed && var.aio_root_ca == null ? 1 : 0
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
  aio_root_ca                    = local.aio_root_ca
  enable_instance_secret_sync    = var.enable_aio_instance_secret_sync
}
