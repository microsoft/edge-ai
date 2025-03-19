output "id" {
  description = "The resource ID for the Storage Account."
  value       = azurerm_storage_account.storage_account.id
}

output "name" {
  description = "The name for the Storage Account."
  value       = azurerm_storage_account.storage_account.name
}
