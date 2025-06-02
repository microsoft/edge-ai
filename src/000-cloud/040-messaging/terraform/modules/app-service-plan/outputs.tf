/*
 * App Service Plan Outputs
 */

output "app_service_plan" {
  description = "The App Service Plan resource object."
  value = {
    id                  = azurerm_service_plan.app_service_plan.id
    name                = azurerm_service_plan.app_service_plan.name
    location            = azurerm_service_plan.app_service_plan.location
    resource_group_name = azurerm_service_plan.app_service_plan.resource_group_name
    os_type             = azurerm_service_plan.app_service_plan.os_type
    sku_name            = azurerm_service_plan.app_service_plan.sku_name
    worker_count        = azurerm_service_plan.app_service_plan.worker_count
    kind                = azurerm_service_plan.app_service_plan.kind
  }
}
