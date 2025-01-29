
output "sse_uami_name" {
  value = azurerm_user_assigned_identity.user_managed_identity_secret_sync.name
}

output "aio_uami_name" {
  value = azurerm_user_assigned_identity.user_managed_identity_aio.name
}
