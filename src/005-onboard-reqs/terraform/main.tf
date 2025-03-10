/**
 * # Onboard Infrastructure Requirements
 *
 * Creates the required resources needed for an edge IaC deployment.
 */

locals {
  resource_group_name = coalesce(
    var.resource_group_name,
    "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  )
  resource_group_id = try(azurerm_resource_group.new[0].id, data.azurerm_resource_group.existing[0].id)
}

resource "azurerm_resource_group" "new" {
  count = var.should_create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "existing" {
  count = var.should_create_resource_group ? 0 : 1

  name = local.resource_group_name
}

module "onboard_identity" {
  source = "./modules/onboard-identity"

  count = var.should_create_onboard_identity ? 1 : 0

  depends_on = [azurerm_resource_group.new]

  location              = var.location
  resource_group_name   = local.resource_group_name
  resource_prefix       = var.resource_prefix
  environment           = var.environment
  instance              = var.instance
  resource_group_id     = local.resource_group_id
  onboard_identity_type = var.onboard_identity_type
}
