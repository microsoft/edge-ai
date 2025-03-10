/**
 * # Azure Key Vault for Secret Sync Extension
 *
 * Create or use and existing a Key Vault for Secret Sync Extension
 *
 */

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "new" {
  name                      = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true
}
