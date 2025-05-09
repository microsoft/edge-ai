/**
 * # Azure Key Vault for Secret Sync Extension
 *
 * Create or use and existing a Key Vault for Secret Sync Extension
 *
 */

data "azurerm_client_config" "current" {}

/*
 * Key Vault
 */

resource "azurerm_key_vault" "new" {
  name                      = coalesce(var.key_vault_name, "kv-${var.resource_prefix}-${var.environment}-${var.instance}")
  location                  = var.location
  resource_group_name       = var.resource_group.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true
}

/*
 * Role Assignments
 */

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  count = var.key_vault_admin_principal_id != null ? 1 : 0

  scope                = azurerm_key_vault.new.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.key_vault_admin_principal_id
}

// Needed to prevent creating Secrets without the Role Assignment already configured.
resource "terraform_data" "defer" {
  input = {
    key_vault = {
      id        = azurerm_key_vault.new.id
      name      = azurerm_key_vault.new.name
      vault_uri = azurerm_key_vault.new.vault_uri
    }
  }
  depends_on = [azurerm_role_assignment.user_key_vault_secrets_officer]
}
