/**
 * # Key Vault Role Assignment
 *
 * Assigns Azure RBAC roles for Key Vault access
 */

/*
 * Role Assignments
 */

// Assign Secrets Officer role at vault level
resource "azurerm_role_assignment" "secrets_officer" {
  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.arc_onboarding_principal_id
}

// Assign Key Vault Reader role at vault level for listing secrets
resource "azurerm_role_assignment" "key_vault_reader" {
  scope                = var.key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.arc_onboarding_principal_id
}

// Assign Secrets User role for server script
resource "azurerm_role_assignment" "server_script_secrets_user" {
  scope                = "${var.key_vault.id}/secrets/${var.server_script_secret_name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.arc_onboarding_principal_id
}

// Assign Secrets User role for node script
resource "azurerm_role_assignment" "node_script_secrets_user" {
  scope                = "${var.key_vault.id}/secrets/${var.node_script_secret_name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.arc_onboarding_principal_id
}
