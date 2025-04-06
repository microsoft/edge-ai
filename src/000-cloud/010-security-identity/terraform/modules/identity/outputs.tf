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
  value = {
    id           = azurerm_user_assigned_identity.user_managed_identity_aio.id
    name         = azurerm_user_assigned_identity.user_managed_identity_aio.name
    principal_id = azurerm_user_assigned_identity.user_managed_identity_aio.principal_id
    client_id    = azurerm_user_assigned_identity.user_managed_identity_aio.client_id
    tenant_id    = azurerm_user_assigned_identity.user_managed_identity_aio.tenant_id
  }
}

output "secret_sync_identity" {
  value = {
    id           = azurerm_user_assigned_identity.user_managed_identity_secret_sync.id
    name         = azurerm_user_assigned_identity.user_managed_identity_secret_sync.name
    principal_id = azurerm_user_assigned_identity.user_managed_identity_secret_sync.principal_id
    client_id    = azurerm_user_assigned_identity.user_managed_identity_secret_sync.client_id
    tenant_id    = azurerm_user_assigned_identity.user_managed_identity_secret_sync.tenant_id
  }
}
