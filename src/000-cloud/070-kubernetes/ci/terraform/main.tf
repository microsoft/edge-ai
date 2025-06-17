# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
locals {
  label_prefix = "${var.resource_prefix}-aio-${var.environment}-${var.instance}"
}

resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_network_security_group" "aio_edge" {
  name                = "nsg-${local.label_prefix}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_virtual_network" "aio_edge" {
  name                = "vnet-${local.label_prefix}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_azurerm_container_registry" "acr" {
  name                = "acr${var.resource_prefix}${var.environment}${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  resource_group         = data.azurerm_resource_group.aio
  network_security_group = data.azurerm_network_security_group.aio_edge
  virtual_network        = data.azurerm_virtual_network.aio_edge
  acr                    = data.azurerm_azurerm_container_registry.acr
  environment            = var.environment
  resource_prefix        = var.resource_prefix
  location               = var.location
  instance               = var.instance
}
