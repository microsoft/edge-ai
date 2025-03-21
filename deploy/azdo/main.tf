/**
 * # Azure Key Vault for Secret Sync Extension
 *
 * Create or use and existing a Key Vault for Secret Sync Extension
 *
 */

locals {
  resource_group_name = coalesce(var.resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = var.location
}

data "azurerm_client_config" "current" {}

module "network" {
  source = "./modules/network"

  resource_group  = azurerm_resource_group.resource_group
  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
}

module "storage_account" {
  source = "./modules/storage-account"

  resource_group  = azurerm_resource_group.resource_group
  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
}

module "key_vault" {
  source = "./modules/key-vault"

  resource_group  = azurerm_resource_group.resource_group
  vnet            = module.network.vnet
  snet_kv         = module.network.snet_kv
  tenant_id       = data.azurerm_client_config.current.tenant_id
  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
}

module "managed_pool" {
  source = "./modules/devops-infra-pool"

  resource_group  = azurerm_resource_group.resource_group
  snet_pool       = module.network.snet_pool
  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
}

module "identity" {
  source = "./modules/identity"

  resource_group  = azurerm_resource_group.resource_group
  key_vault       = module.key_vault.key_vault
  storage_account = module.storage_account.storage_account
  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
}
