/**
 * # Azure Container Registry for Accelerator
 *
 * Create a Container Registry to host the artifacts for the Accelerator
 *
 */

resource "azurerm_container_registry" "acr" {
  name                          = "acr${var.resource_prefix}${var.environment}${var.instance}"
  resource_group_name           = var.resource_group.name
  location                      = var.resource_group.location
  sku                           = var.sku
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "pep" {
  name                = "pep-${azurerm_container_registry.acr.name}"
  location            = var.resource_group.location
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
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-pzl-acr-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = var.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = azurerm_container_registry.acr.name
  zone_name           = azurerm_private_dns_zone.dns_zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pep.private_service_connection[0].private_ip_address]
}
