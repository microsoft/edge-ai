/**
 * # Azure Functions
 *
 * Creates an Azure Function App that runs on the provided App Service Plan.
 * This module creates the Function App with necessary configuration for messaging scenarios.
 */

resource "azurerm_storage_account" "function_storage" {
  name                     = "st${lower(var.resource_prefix)}${lower(var.environment)}fn${var.instance}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_linux_function_app" "function_app" {
  count = var.app_service_plan.os_type == "Linux" ? 1 : 0

  name                = "func-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = var.app_service_plan.id

  site_config {
    application_stack {
      node_version = var.node_version
    }

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }
  }

  app_settings = var.app_settings

  tags = var.tags
}

resource "azurerm_windows_function_app" "function_app" {
  count = var.app_service_plan.os_type == "Windows" ? 1 : 0

  name                = "func-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = var.app_service_plan.id

  site_config {
    application_stack {
      node_version = var.node_version
    }

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }
  }

  app_settings = var.app_settings

  tags = var.tags
}
