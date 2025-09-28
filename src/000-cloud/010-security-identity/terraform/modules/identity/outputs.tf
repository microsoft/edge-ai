output "arc_onboarding_sp" {
  value = try({
    client_id     = azuread_application.aio_edge[0].client_id
    object_id     = azuread_service_principal.aio_edge[0].object_id
    client_secret = azuread_application_password.aio_edge[0].value
  }, null)
  sensitive = true
}

output "arc_onboarding_identity" {
  value = try({
    id           = azurerm_user_assigned_identity.arc_onboarding[0].id
    name         = azurerm_user_assigned_identity.arc_onboarding[0].name
    principal_id = azurerm_user_assigned_identity.arc_onboarding[0].principal_id
    client_id    = azurerm_user_assigned_identity.arc_onboarding[0].client_id
    tenant_id    = azurerm_user_assigned_identity.arc_onboarding[0].tenant_id
  }, null)
}

output "aio_identity" {
  value = try({
    id           = azurerm_user_assigned_identity.user_managed_identity_aio[0].id
    name         = azurerm_user_assigned_identity.user_managed_identity_aio[0].name
    principal_id = azurerm_user_assigned_identity.user_managed_identity_aio[0].principal_id
    client_id    = azurerm_user_assigned_identity.user_managed_identity_aio[0].client_id
    tenant_id    = azurerm_user_assigned_identity.user_managed_identity_aio[0].tenant_id
  }, null)
}

output "secret_sync_identity" {
  value = try({
    id           = azurerm_user_assigned_identity.user_managed_identity_secret_sync[0].id
    name         = azurerm_user_assigned_identity.user_managed_identity_secret_sync[0].name
    principal_id = azurerm_user_assigned_identity.user_managed_identity_secret_sync[0].principal_id
    client_id    = azurerm_user_assigned_identity.user_managed_identity_secret_sync[0].client_id
    tenant_id    = azurerm_user_assigned_identity.user_managed_identity_secret_sync[0].tenant_id
  }, null)
}

output "ml_workload_identity" {
  description = "The AzureML workload user-assigned identity."
  value = try({
    id           = azurerm_user_assigned_identity.ml_workload[0].id
    client_id    = azurerm_user_assigned_identity.ml_workload[0].client_id
    principal_id = azurerm_user_assigned_identity.ml_workload[0].principal_id
    name         = azurerm_user_assigned_identity.ml_workload[0].name
    tenant_id    = azurerm_user_assigned_identity.ml_workload[0].tenant_id
  }, null)
}

output "aks_identity" {
  description = "The AKS user-assigned identity for custom private DNS zone scenarios."
  value = try({
    id           = azurerm_user_assigned_identity.aks_identity[0].id
    name         = azurerm_user_assigned_identity.aks_identity[0].name
    principal_id = azurerm_user_assigned_identity.aks_identity[0].principal_id
    client_id    = azurerm_user_assigned_identity.aks_identity[0].client_id
    tenant_id    = azurerm_user_assigned_identity.aks_identity[0].tenant_id
  }, null)
}
