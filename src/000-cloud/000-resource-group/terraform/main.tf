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

  tags = {
    Environment = var.environment
    Instance    = var.instance
  }
}

resource "azurerm_resource_group" "new" {
  name     = local.resource_group_name
  location = var.location
  tags     = merge(local.tags, var.tags)
}
