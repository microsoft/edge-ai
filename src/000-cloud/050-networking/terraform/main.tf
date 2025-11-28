/**
 * # Virtual Network
 *
 * Creates a virtual network with subnets and associated network security groups for Azure resources.
 * This component provides the foundational networking infrastructure for cloud resources.
 */

locals {
  // Resource naming following Azure naming conventions
  network_security_group_name = "nsg-${var.resource_prefix}-${var.environment}-${var.instance}"
  subnet_name                 = "snet-${var.resource_prefix}-${var.environment}-${var.instance}"
  virtual_network_name        = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
}

resource "azurerm_network_security_group" "main" {
  name                = local.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group.name

  tags = {
    "azd-env-name" = var.environment
  }
}

resource "azurerm_virtual_network" "main" {
  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group.name
  address_space       = [var.virtual_network_config.address_space]

  tags = {
    "azd-env-name" = var.environment
  }
}

resource "azurerm_subnet" "main" {
  name                            = local.subnet_name
  resource_group_name             = var.resource_group.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = [var.virtual_network_config.subnet_address_prefix]
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

module "nat_gateway" {
  count = var.should_enable_nat_gateway ? 1 : 0

  source = "./modules/nat-gateway"

  resource_group          = var.resource_group
  location                = var.location
  environment             = var.environment
  resource_prefix         = var.resource_prefix
  instance                = var.instance
  public_ip_count         = var.nat_gateway_public_ip_count
  availability_zones      = var.nat_gateway_zones
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_minutes
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  count = var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = module.nat_gateway[0].nat_gateway.id
  subnet_id      = azurerm_subnet.main.id
}

module "private_resolver" {
  count = var.should_enable_private_resolver ? 1 : 0

  source = "./modules/private-resolver"

  resource_group                  = var.resource_group
  virtual_network                 = azurerm_virtual_network.main
  location                        = var.location
  resource_prefix                 = var.resource_prefix
  environment                     = var.environment
  instance                        = var.instance
  default_outbound_access_enabled = var.default_outbound_access_enabled
  resolver_subnet_address_prefix  = var.resolver_subnet_address_prefix
  should_enable_nat_gateway       = var.should_enable_nat_gateway
  nat_gateway_id                  = module.nat_gateway[0].nat_gateway.id
}

resource "azurerm_virtual_network_dns_servers" "main" {
  count = var.should_enable_private_resolver ? 1 : 0

  virtual_network_id = azurerm_virtual_network.main.id
  dns_servers        = [module.private_resolver[0].dns_server_ip]
}
