/**
 * # NAT Gateway
 *
 * Provision a reusable NAT gateway with configurable public IP resources
 * for managed outbound access.
 */

locals {
  nat_gateway_name = "nat-${var.resource_prefix}-${var.environment}-${var.instance}"
  public_ip_prefix = "pip-nat-${var.resource_prefix}-${var.environment}-${var.instance}"
}

resource "azurerm_nat_gateway" "main" {
  name                    = local.nat_gateway_name
  location                = var.location
  resource_group_name     = var.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = length(var.availability_zones) > 0 ? var.availability_zones : null
}

resource "azurerm_public_ip" "nat" {
  count = var.public_ip_count

  name                = "${local.public_ip_prefix}-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.availability_zones) > 0 ? var.availability_zones : null
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.public_ip_count

  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}
