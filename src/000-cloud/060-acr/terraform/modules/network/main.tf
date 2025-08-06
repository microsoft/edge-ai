/**
 * # Virtual Network Module
 *
 * Deploys virtual network resources for ACR
 */

locals {
  label_prefix_acr = "${var.resource_prefix}-acr-${var.environment}-${var.instance}"
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_acr" {
  count = var.should_create_acr_private_endpoint ? 1 : 0

  subnet_id                 = azurerm_subnet.snet_acr[0].id
  network_security_group_id = var.network_security_group.id
}


resource "azurerm_subnet" "snet_acr" {
  count = var.should_create_acr_private_endpoint ? 1 : 0

  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  name                 = "subnet-${local.label_prefix_acr}"
  address_prefixes     = var.subnet_address_prefixes_acr
}
