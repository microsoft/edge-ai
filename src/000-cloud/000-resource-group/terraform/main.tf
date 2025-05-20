/**
 * # Onboard Infrastructure Requirements
 *
 * Creates the required resources needed for an edge IaC deployment or uses an existing resource group.
 */

locals {
  resource_group_name = coalesce(
    var.resource_group_name,
    "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  )

  tags = {
    Environment = var.environment
    Instance    = var.instance
  }
}

# Create a new resource group if use_existing_resource_group is false
resource "azurerm_resource_group" "new" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = local.resource_group_name
  location = var.location
  tags     = merge(local.tags, var.tags)
}

# Data source for existing resource group if use_existing_resource_group is true
data "azurerm_resource_group" "existing" {
  count = var.use_existing_resource_group ? 1 : 0
  name  = local.resource_group_name
}
