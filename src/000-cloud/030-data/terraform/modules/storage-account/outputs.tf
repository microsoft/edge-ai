output "storage_account" {
  description = "The newly created Storage Account."
  value = {
    id                     = azurerm_storage_account.storage_account.id
    name                   = azurerm_storage_account.storage_account.name
    primary_blob_endpoint  = azurerm_storage_account.storage_account.primary_blob_endpoint
    primary_file_endpoint  = azurerm_storage_account.storage_account.primary_file_endpoint
    primary_queue_endpoint = azurerm_storage_account.storage_account.primary_queue_endpoint
    primary_table_endpoint = azurerm_storage_account.storage_account.primary_table_endpoint
  }
}
