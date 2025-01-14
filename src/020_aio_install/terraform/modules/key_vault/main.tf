/**
 * # Azure Key Vault
 *
 * Deploys a Key Vault account to be used for further configuring Azure IoT Operations deployments
 *
 */

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "aio_key_vault" {
  name                      = "${var.resource_prefix}-kv"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true
}

resource "azurerm_user_assigned_identity" "user_managed_identity_secret_sync" {
  location            = var.location
  name                = "${var.resource_prefix}-sse-umi"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.aio_key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "umi_key_vault_reader" {
  scope                = azurerm_key_vault.aio_key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}

resource "azurerm_role_assignment" "umi_key_vault_secrets_user" {
  scope                = azurerm_key_vault.aio_key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}
