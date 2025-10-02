/**
 * # Azure Container Registry for Accelerator
 *
 * Deploys Azure Container Registry with a private endpoint and private DNS zone.
 *
 */

locals {
  allowed_public_ip_ranges       = try(var.allowed_public_ip_ranges, [])
  sanitized_location             = lower(replace(var.location, " ", ""))
  should_enable_data_endpoint    = alltrue([var.should_enable_data_endpoints, var.should_create_acr_private_endpoint, lower(var.sku) == "premium"])
  should_configure_network_rules = alltrue([var.public_network_access_enabled, length(local.allowed_public_ip_ranges) > 0])
}

resource "azurerm_container_registry" "acr" {
  name                          = "acr${replace(var.resource_prefix, "-", "")}${replace(var.environment, "-", "")}${var.instance}"
  resource_group_name           = var.resource_group.name
  location                      = var.location
  sku                           = var.sku
  public_network_access_enabled = var.public_network_access_enabled
  data_endpoint_enabled         = local.should_enable_data_endpoint
  network_rule_bypass_option    = var.allow_trusted_services ? "AzureServices" : "None"

  dynamic "network_rule_set" {
    for_each = local.should_configure_network_rules ? [1] : []
    content {
      default_action = "Deny"
      ip_rule = [
        for ip_cidr in local.allowed_public_ip_ranges : {
          action   = "Allow"
          ip_range = ip_cidr
        }
      ]
    }
  }
}

resource "azurerm_private_endpoint" "pep" {
  count = var.should_create_acr_private_endpoint ? 1 : 0

  name                = "pe-acr-${azurerm_container_registry.acr.name}"
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
  count = var.should_create_acr_private_endpoint ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.should_create_acr_private_endpoint ? 1 : 0

  name                  = "vnet-pzl-acr-${replace(var.resource_prefix, "-", "")}-${replace(var.environment, "-", "")}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone[0].name
  virtual_network_id    = var.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "a_record" {
  count = var.should_create_acr_private_endpoint ? 1 : 0

  name                = azurerm_container_registry.acr.name
  zone_name           = azurerm_private_dns_zone.dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records = one([
    for config in azurerm_private_endpoint.pep[0].custom_dns_configs : config.ip_addresses
    if lower(config.fqdn) == "${azurerm_container_registry.acr.name}.azurecr.io"
  ])
}

resource "azurerm_private_dns_a_record" "data_endpoint" {
  count = local.should_enable_data_endpoint ? 1 : 0

  name                = "${azurerm_container_registry.acr.name}.${local.sanitized_location}.data"
  zone_name           = azurerm_private_dns_zone.dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records = one([
    for config in azurerm_private_endpoint.pep[0].custom_dns_configs : config.ip_addresses
    if lower(config.fqdn) == "${azurerm_container_registry.acr.name}.${local.sanitized_location}.data.azurecr.io"
  ])
}
