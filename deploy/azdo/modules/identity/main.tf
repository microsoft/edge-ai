/**
 * # Identities for Accelerator
 *
 * Create User Assigned Managed Identities for Accelerator and assign roles to them
 *
 */

// Create a user assigned managed identity for the AzDO service connection
resource "azurerm_user_assigned_identity" "user_managed_identity" {
  location            = var.resource_group.location
  name                = "id-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
}

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity.principal_id
}

resource "azurerm_role_assignment" "user_storage_account_owner" {
  scope                = var.storage_account.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity.principal_id
}

