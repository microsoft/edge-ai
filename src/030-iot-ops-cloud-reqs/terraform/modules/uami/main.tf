/**
 * # User Assigned Managed Identities for Azure IoT Operations
 *
 * Create User Assigned Managed Identities for Azure IoT Operations and assign roles to them
 *
 */

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "user_managed_identity_secret_sync" {
  location            = var.location
  name                = "uami-${var.resource_prefix}-${var.environment}-sse-${var.instance}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "user_managed_identity_aio" {
  location            = var.location
  name                = "uami-${var.resource_prefix}-${var.environment}-aio-${var.instance}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "uami_key_vault_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}

resource "azurerm_role_assignment" "uami_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
}

