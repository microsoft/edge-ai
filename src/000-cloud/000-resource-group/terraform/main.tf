/**
 * # Onboard Infrastructure Requirements
 *
 * Creates the required resources needed for an edge IaC deployment or uses an existing resource group.
 */

locals {
  # Determine resource group name based on input or fallback to default pattern
  resource_group_name = var.resource_group_name != "" && var.resource_group_name != null ? var.resource_group_name : "rg-${var.resource_prefix}-${var.environment}-${var.instance}"

  # Default tags for the resource group
  tags = {
    Environment = var.environment
    Instance    = var.instance
  }

  # Check if the resource group already exists
  rg_exists = contains(data.azapi_resource_list.listResourceGroups.output.name, local.resource_group_name)
}
# Required variables for the resource group
data "azurerm_client_config" "current" {}

# Data source to get the current Azure subscription configuration
data "azapi_resource_list" "listResourceGroups" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  response_export_values = {
    name = "value[?name=='${local.resource_group_name}'].name"
  }
}

# Data source for existing resource group (only if it actually exists)
data "azurerm_resource_group" "existing" {
  count = local.rg_exists ? 1 : 0
  name  = local.resource_group_name
}
# Create a new resource group if needed
resource "azurerm_resource_group" "new" {
  count    = !local.rg_exists ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = merge(local.tags, var.tags)
}
