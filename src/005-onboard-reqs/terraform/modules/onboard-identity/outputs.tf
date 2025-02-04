output "arc_onboarding_user_managed_identity_id" {
  value = try(azurerm_user_assigned_identity.arc_onboarding[0].id, "")
}

output "arc_onboarding_user_managed_identity_name" {
  value = try(azurerm_user_assigned_identity.arc_onboarding[0].name, "")
}

output "sp_client_id" {
  value = try(azuread_application.aio_edge[0].client_id, "")
}

output "sp_client_secret" {
  value     = try(azuread_application_password.aio_edge[0].value, "")
  sensitive = true
}

output "arc_onboarding_user_assigned_identity" {
  value = try(azurerm_user_assigned_identity.arc_onboarding[0], null)
}
