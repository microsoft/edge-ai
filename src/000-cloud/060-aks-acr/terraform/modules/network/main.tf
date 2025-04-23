/**
 * # Virtual Network Module
 *
 * Deploys virtual network resources for ACR and AKS
 */

locals {
  label_prefix_acr     = "${var.resource_prefix}-acr-${var.environment}-${var.instance}"
  label_prefix_aks     = "${var.resource_prefix}-aks-${var.environment}-${var.instance}"
  label_prefix_aks_pod = "${var.resource_prefix}-aks-pod-${var.environment}-${var.instance}"
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_acr" {
  count = var.should_create_private_endpoint ? 1 : 0

  subnet_id                 = azurerm_subnet.snet_acr[0].id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks" {
  subnet_id                 = azurerm_subnet.snet_aks.id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks_pod" {
  subnet_id                 = azurerm_subnet.snet_aks_pod.id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet" "snet_acr" {
  count = var.should_create_private_endpoint ? 1 : 0

  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  name                 = "subnet-${local.label_prefix_acr}"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "snet_aks" {
  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  name                 = "subnet-${local.label_prefix_aks}"
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "snet_aks_pod" {
  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  name                 = "subnet-${local.label_prefix_aks_pod}"
  address_prefixes     = ["10.0.4.0/24"]
}
