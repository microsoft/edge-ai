/**
 * # Azure Functions
 *
 * Creates an Azure Function App that runs on the provided App Service Plan.
 * This module creates the Function App with necessary configuration for messaging scenarios.
 */

resource "azurerm_user_assigned_identity" "function_identity" {
  name                = "id-func-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_storage_account" "function_storage" {
  name                            = "st${lower(var.resource_prefix)}${lower(var.environment)}fn${var.instance}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_role_assignment" "function_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.function_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

resource "azurerm_role_assignment" "function_storage_queue_data_contributor" {
  scope                = azurerm_storage_account.function_storage.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

resource "azurerm_role_assignment" "function_storage_table_data_contributor" {
  scope                = azurerm_storage_account.function_storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

resource "azurerm_linux_function_app" "function_app" {
  count = var.app_service_plan.os_type == "Linux" ? 1 : 0

  name                = "func-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_uses_managed_identity = true
  service_plan_id               = var.app_service_plan.id

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_identity.id]
  }

  site_config {
    application_stack {
      node_version   = var.python_version == null ? var.node_version : null
      python_version = var.python_version
    }

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      AZURE_CLIENT_ID              = azurerm_user_assigned_identity.function_identity.client_id
      EventHubConnection__clientId = azurerm_user_assigned_identity.function_identity.client_id
    }
  )

  depends_on = [
    azurerm_role_assignment.function_storage_blob_data_contributor,
    azurerm_role_assignment.function_storage_queue_data_contributor,
    azurerm_role_assignment.function_storage_table_data_contributor
  ]

  tags = var.tags
}

resource "azurerm_windows_function_app" "function_app" {
  count = var.app_service_plan.os_type == "Windows" ? 1 : 0

  name                = "func-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_uses_managed_identity = true
  service_plan_id               = var.app_service_plan.id

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_identity.id]
  }

  site_config {
    application_stack {
      node_version = var.node_version
    }

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      AZURE_CLIENT_ID              = azurerm_user_assigned_identity.function_identity.client_id
      EventHubConnection__clientId = azurerm_user_assigned_identity.function_identity.client_id
    }
  )

  depends_on = [
    azurerm_role_assignment.function_storage_blob_data_contributor,
    azurerm_role_assignment.function_storage_queue_data_contributor,
    azurerm_role_assignment.function_storage_table_data_contributor
  ]

  tags = var.tags
}
