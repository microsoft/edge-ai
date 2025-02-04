
output "sse_uami_name" {
  value = azurerm_user_assigned_identity.user_managed_identity_secret_sync.name
}

output "aio_uami_name" {
  value = azurerm_user_assigned_identity.user_managed_identity_aio.name
}

output "aio_user_assigned_identity" {
  value = azurerm_user_assigned_identity.user_managed_identity_aio
}

output "sse_user_assigned_identity" {
  value = azurerm_user_assigned_identity.user_managed_identity_secret_sync
}
