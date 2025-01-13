output "name" {
  value = azurerm_key_vault.aio_key_vault.name
}

output "sse_user_managed_identity_name" {
  value = azurerm_user_assigned_identity.user_managed_identity_secret_sync.name
}
