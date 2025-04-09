/**
 * # Azure DevOps Network Module
 *
 * Creates the networking infrastructure required for Azure DevOps infrastructure:
 *
 * - Virtual Network with dedicated subnets for Key Vault, DevOps Agent Pool, and Container Registry
 * - Network Security Group with appropriate associations
 * - Private DNS Zone with VNet link
 * - Network role assignments for DevOps service principals
 */

data "azuread_service_principal" "service_principal" {
  display_name = "DevOpsInfrastructure"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  address_space       = ["10.0.0.0/16"]
}

// required to link the vnet to the managed devops pool
resource "azurerm_role_assignment" "user_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azuread_service_principal.service_principal.object_id
}

// required to link the vnet to the managed devops pool
resource "azurerm_role_assignment" "user_reader" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_service_principal.service_principal.object_id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}


resource "azurerm_subnet_network_security_group_association" "snet_nsg_kv" {
  subnet_id                 = azurerm_subnet.snet_kv.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_pool" {
  subnet_id                 = azurerm_subnet.snet_pool.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_acr" {
  subnet_id                 = azurerm_subnet.snet_acr.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "snet_kv" {
  name                 = "snet-keyvault"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "snet_pool" {
  name                 = "snet-pool"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
    name = "Microsoft.DevOpsInfrastructure/pools"
    service_delegation {
      name    = "Microsoft.DevOpsInfrastructure/pools"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "snet_acr" {
  name                 = "snet-acr"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}
