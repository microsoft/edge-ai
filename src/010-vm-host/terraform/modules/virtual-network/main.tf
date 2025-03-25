/**
 * # Virtual Network Module
 *
 * Deploys virtual network resources for VM hosts
 */

resource "azurerm_network_security_group" "aio_edge" {
  name                = "nsg-${var.label_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_virtual_network" "aio_edge" {
  name                = "vnet-${var.label_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aio_edge" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aio_edge.name
  name                 = "subnet-${var.label_prefix}"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "aio_edge" {
  subnet_id                 = azurerm_subnet.aio_edge.id
  network_security_group_id = azurerm_network_security_group.aio_edge.id
}