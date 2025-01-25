output "key_vault" {
  value = {
    name = local.key_vault_name
    id   = local.key_vault_id
  }
}

output "sse_user_managed_identity" {
  value = {
    id        = azurerm_user_assigned_identity.user_managed_identity_secret_sync.id
    client_id = azurerm_user_assigned_identity.user_managed_identity_secret_sync.client_id
  }
}
