/*
 * Function App Outputs
 */

output "function_identity" {
  description = "The User Assigned Managed Identity used by the Function App."
  value = {
    principal_id = azurerm_user_assigned_identity.function_identity.principal_id
    client_id    = azurerm_user_assigned_identity.function_identity.client_id
  }
}

output "function_app" {
  description = "The Function App resource object."
  value = {
    id                  = try(azurerm_linux_function_app.function_app[0].id, azurerm_windows_function_app.function_app[0].id)
    name                = try(azurerm_linux_function_app.function_app[0].name, azurerm_windows_function_app.function_app[0].name)
    default_hostname    = try(azurerm_linux_function_app.function_app[0].default_hostname, azurerm_windows_function_app.function_app[0].default_hostname)
    principal_id        = azurerm_user_assigned_identity.function_identity.principal_id
    client_id           = azurerm_user_assigned_identity.function_identity.client_id
    resource_group_name = var.resource_group_name
    location            = var.location
    os_type             = var.app_service_plan.os_type
  }
}

output "storage_account" {
  description = "The Storage Account used by the Function App."
  value = {
    id                    = azurerm_storage_account.function_storage.id
    name                  = azurerm_storage_account.function_storage.name
    primary_blob_endpoint = azurerm_storage_account.function_storage.primary_blob_endpoint
  }
}
