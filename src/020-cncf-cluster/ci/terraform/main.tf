# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_machine" "aio" {
  name                = "vm-${var.resource_prefix}-${var.environment}-aio-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "cncf_cluster" {
  source = "../../terraform"

  environment          = var.environment
  instance             = var.instance
  resource_prefix      = var.resource_prefix
  custom_locations_oid = var.custom_locations_oid
  aio_resource_group   = data.azurerm_resource_group.aio
  aio_virtual_machine  = data.azurerm_virtual_machine.aio
}
