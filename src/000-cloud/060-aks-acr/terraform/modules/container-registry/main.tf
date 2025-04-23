/**
 * # Azure Container Registry for Accelerator
 *
 * Deploys Azure Container Registry with a private endpoint and private DNS zone.
 *
 */

resource "azurerm_container_registry" "acr" {
  name                          = "acr${var.resource_prefix}${var.environment}${var.instance}"
  resource_group_name           = var.resource_group.name
  location                      = var.location
  sku                           = var.sku
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "pep" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = "pep-${azurerm_container_registry.acr.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.snet_acr.id

  private_service_connection {
    name                           = "acr-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
  }
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                  = "vnet-pzl-acr-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone[0].name
  virtual_network_id    = var.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "a_record" {
  count = var.should_create_private_endpoint ? 1 : 0

  name                = azurerm_container_registry.acr.name
  zone_name           = azurerm_private_dns_zone.dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pep[0].private_service_connection[0].private_ip_address]
}
