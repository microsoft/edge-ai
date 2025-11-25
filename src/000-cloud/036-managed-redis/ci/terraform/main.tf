// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
resource "terraform_data" "defer" {
  input = {
    resource_group_name  = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    virtual_network_name = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_network" "this" {
  name                = terraform_data.defer.output.virtual_network_name
  resource_group_name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source = "../../terraform"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_group  = data.azurerm_resource_group.aio
  resource_prefix = var.resource_prefix

  virtual_network = data.azurerm_virtual_network.this
}
