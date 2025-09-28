/**
 * # Azure Private Resolver for VPN Client DNS Resolution
 *
 * Deploys Azure Private Resolver with inbound endpoints to enable VPN clients
 * to resolve private DNS zones for Azure services behind private endpoints.
 * This solves the common issue where VPN clients cannot resolve private endpoints.
 */

locals {
  private_resolver_name = "dnspr-${var.resource_prefix}-${var.environment}-${var.instance}"
  inbound_endpoint_name = "ipe-${var.resource_prefix}-${var.environment}-${var.instance}"
  resolver_subnet_name  = "snet-resolver-${var.resource_prefix}-${var.environment}-${var.instance}"
}

/*
 * Subnet for Private Resolver
 */

resource "azurerm_subnet" "resolver_subnet" {
  name                            = local.resolver_subnet_name
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  address_prefixes                = [var.resolver_subnet_address_prefix]
  default_outbound_access_enabled = var.default_outbound_access_enabled

  // Private Resolver subnet requires this delegation
  delegation {
    name = "Microsoft.Network.dnsResolvers"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
      name = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "resolver" {
  count = var.nat_gateway_id != null ? 1 : 0

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.resolver_subnet.id
}

/*
 * Azure Private Resolver
 */

resource "azurerm_private_dns_resolver" "main" {
  name                = local.private_resolver_name
  resource_group_name = var.resource_group.name
  location            = var.location
  virtual_network_id  = var.virtual_network.id
}

/*
 * Inbound Endpoint for DNS Resolution
 */

resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  name                    = local.inbound_endpoint_name
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  location                = var.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.resolver_subnet.id
  }
}
