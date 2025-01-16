/**
 * # Azure Key Vault for Secret Sync Extension
 *
 * Create or use and existing a Key Vault and configure it for use by Secret Sync Extension
 *
 */

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "existing" {
  name                = var.existing_key_vault_name
  resource_group_name = var.resource_group_name

  count = var.existing_key_vault_name == null ? 0 : 1
}

resource "azurerm_key_vault" "new" {
  name                      = "${var.resource_prefix}-kv"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true

  count = var.existing_key_vault_name == null ? 1 : 0
}

locals {
  key_vault_id   = length(data.azurerm_key_vault.existing) > 0 ? data.azurerm_key_vault.existing[0].id : azurerm_key_vault.new[0].id
  key_vault_name = length(data.azurerm_key_vault.existing) > 0 ? data.azurerm_key_vault.existing[0].name : azurerm_key_vault.new[0].name
}

resource "azurerm_user_assigned_identity" "user_managed_identity_secret_sync" {
  location            = var.location
  name                = "${var.resource_prefix}-sse-umi"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "umi_key_vault_reader" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}

resource "azurerm_role_assignment" "umi_key_vault_secrets_user" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}
