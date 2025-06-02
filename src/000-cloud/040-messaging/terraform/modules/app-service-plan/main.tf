/**
 * # Azure App Service Plan
 *
 * Creates an Azure App Service Plan that can be used to host Azure Functions and other web applications.
 * This module provides the compute infrastructure needed for serverless and web applications.
 */

resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}
