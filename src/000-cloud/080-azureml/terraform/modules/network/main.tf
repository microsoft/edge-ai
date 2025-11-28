/**
 * # Virtual Network Module
 *
 * Deploys virtual network resources for Azure ML compute clusters
 */

locals {
  label_prefix_azureml = "${var.resource_prefix}-azureml-${var.environment}-${var.instance}"
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_azureml" {
  count = var.should_associate_network_security_group ? 1 : 0

  subnet_id                 = azurerm_subnet.snet_azureml.id
  network_security_group_id = try(var.network_security_group.id, null)
}

resource "azurerm_subnet" "snet_azureml" {
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  name                            = "subnet-${local.label_prefix_azureml}"
  address_prefixes                = var.subnet_address_prefixes_azureml
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

resource "azurerm_subnet_nat_gateway_association" "snet_azureml" {
  count = var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.snet_azureml.id
}
