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
  name                 = local.subnet_name
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.virtual_network_config.subnet_address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
