/**
 * # Azure Key Vault Module for DevOps Infrastructure
 *
 * Creates an Azure Key Vault with private endpoint connectivity:
 *
 * - Key Vault with RBAC authorization enabled
 * - Private endpoint for secure network access
 * - Private DNS A record for name resolution
 * - Public network access disabled for enhanced security
 */

resource "azurerm_key_vault" "key_vault" {
  name                          = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  location                      = var.resource_group.location
  resource_group_name           = var.resource_group.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = false
  enable_rbac_authorization     = true
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "pep" {
  name                = "pep-${azurerm_key_vault.key_vault.name}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.snet_kv.id

  private_service_connection {
    name                           = "keyvault-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-pzl-kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = var.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = azurerm_key_vault.key_vault.name
  zone_name           = azurerm_private_dns_zone.dns_zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pep.private_service_connection[0].private_ip_address]
}
