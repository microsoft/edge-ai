output "key_vault" {
  value = {
    id        = azurerm_key_vault.new.id
    name      = azurerm_key_vault.new.name
    vault_uri = azurerm_key_vault.new.vault_uri
  }
}
