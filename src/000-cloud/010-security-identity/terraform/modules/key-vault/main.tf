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
  name                          = coalesce(var.key_vault_name, "kv-${var.resource_prefix}-${var.environment}-${var.instance}")
  location                      = var.location
  resource_group_name           = var.resource_group.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = false
  rbac_authorization_enabled    = true
  public_network_access_enabled = var.should_enable_public_network_access
}

/*
 * Role Assignments
 */

resource "azurerm_role_assignment" "user_key_vault_secrets_officer" {
  count = var.should_add_key_vault_role_assignment ? 1 : 0

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

/*
 * Private Endpoint
 */

resource "azurerm_private_endpoint" "key_vault" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = "pe-${azurerm_key_vault.new.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "kv-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.new.id
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                  = "vnet-pzl-kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "a_record" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = azurerm_key_vault.new.name
  zone_name           = azurerm_private_dns_zone.dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.key_vault[0].private_service_connection[0].private_ip_address]
}
