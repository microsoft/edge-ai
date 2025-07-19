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

data "azurerm_user_assigned_identity" "aio" {
  name                = "id-${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance
  eventhubs       = var.eventhubs
  resource_group  = data.azurerm_resource_group.aio
  aio_identity    = data.azurerm_user_assigned_identity.aio
}
