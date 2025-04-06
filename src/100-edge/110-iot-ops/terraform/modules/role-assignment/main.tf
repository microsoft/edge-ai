/*
 * # Role Assignments
 */

resource "azurerm_role_assignment" "secret_sync_key_vault_reader" {
  scope                = var.secret_sync_key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.secret_sync_identity.principal_id
}

resource "azurerm_role_assignment" "secret_sync_key_vault_user" {
  scope                = var.secret_sync_key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.secret_sync_identity.principal_id
}
