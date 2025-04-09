/**
 * # Azure DevOps Infrastructure Module
 *
 * Creates or uses existing Azure resources for Azure DevOps integration:
 *
 * - Resource Group
 * - Virtual Network with subnets for Key Vault, ACR, and DevOps agent pool
 * - Storage Account
 * - Key Vault with private endpoint
 * - Container Registry with private endpoint
 * - DevOps Managed Pool
 * - User Assigned Managed Identity with appropriate role assignments
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

  // Resource dependencies first
  resource_group = azurerm_resource_group.resource_group

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "storage_account" {
  source = "./modules/storage-account"

  // Resource dependencies first
  resource_group = azurerm_resource_group.resource_group

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "key_vault" {
  source = "./modules/key-vault"

  // Resource dependencies first
  resource_group = azurerm_resource_group.resource_group
  snet_kv        = module.network.snet_kv
  vnet           = module.network.vnet
  tenant_id      = data.azurerm_client_config.current.tenant_id

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "managed_pool" {
  source = "./modules/devops-infra-pool"

  // Resource dependencies first
  resource_group = azurerm_resource_group.resource_group
  snet_pool      = module.network.snet_pool

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "acr" {
  source = "./modules/container-registry"

  // Resource dependencies first
  resource_group = azurerm_resource_group.resource_group
  snet_acr       = module.network.snet_acr
  vnet           = module.network.vnet

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}

module "identity" {
  source = "./modules/identity"

  // Resource dependencies first
  resource_group  = azurerm_resource_group.resource_group
  key_vault       = module.key_vault.key_vault
  storage_account = module.storage_account.storage_account
  acr             = module.acr.acr

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
}
