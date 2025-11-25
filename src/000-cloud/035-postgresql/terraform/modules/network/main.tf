/**
 * # PostgreSQL Networking Module
 *
 * Creates delegated subnet for PostgreSQL Flexible Server
 */

locals {
  subnet_name = "snet-postgres-${var.resource_prefix}-${var.environment}-${var.instance}"
}

resource "azurerm_subnet" "postgres" {
  name                            = local.subnet_name
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  address_prefixes                = var.subnet_address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled

  delegation {
    name = "postgres-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "postgres" {
  subnet_id                 = azurerm_subnet.postgres.id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet_nat_gateway_association" "postgres" {
  count = var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = var.nat_gateway.id
  subnet_id      = azurerm_subnet.postgres.id
}

/*
 * Private DNS Zone - Created before PostgreSQL server
 */

resource "azurerm_private_dns_zone" "postgres" {
  count = var.should_create_private_dns_zone ? 1 : 0

  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count = var.should_create_private_dns_zone ? 1 : 0

  name                  = "pdnsz-link-${var.resource_prefix}-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.virtual_network.id
  resource_group_name   = var.resource_group.name
}
