/**
 * # Azure IoT Operations Cloud Requirements
 *
 * Sets up required cloud resources for Azure IoT Operations installation
 * including: Schema Registry, Azure Key Vault, and Roles and Permissions for
 * access to resources.
 */

locals {
  key_vault_admin_principal_id = try(coalesce(var.key_vault_admin_principal_id, data.azurerm_client_config.current[0].object_id), null)
}

data "azurerm_client_config" "current" {
  count = var.should_use_current_user_key_vault_admin ? 1 : 0
}

module "key_vault" {
  count = var.should_create_key_vault ? 1 : 0

  source = "./modules/key-vault"

  location                            = var.location
  resource_group                      = var.aio_resource_group
  resource_prefix                     = var.resource_prefix
  environment                         = var.environment
  instance                            = var.instance
  key_vault_name                      = var.key_vault_name
  key_vault_admin_principal_id        = local.key_vault_admin_principal_id
  should_create_private_endpoint      = var.should_create_key_vault_private_endpoint
  private_endpoint_subnet_id          = var.key_vault_private_endpoint_subnet_id
  virtual_network_id                  = var.key_vault_virtual_network_id
  should_enable_public_network_access = var.should_enable_public_network_access
}

module "identity" {
  count = var.should_create_identities ? 1 : 0

  source = "./modules/identity"

  location                           = var.location
  resource_group                     = var.aio_resource_group
  resource_prefix                    = var.resource_prefix
  environment                        = var.environment
  instance                           = var.instance
  onboard_identity_type              = var.onboard_identity_type
  should_create_aks_identity         = var.should_create_aks_identity
  should_create_secret_sync_identity = var.should_create_secret_sync_identity
  should_create_aio_identity         = var.should_create_aio_identity
  should_create_ml_workload_identity = var.should_create_ml_workload_identity
}
