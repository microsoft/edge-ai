output "id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.storage_account.id
}

output "name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.storage_account.name
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location."
  value       = azurerm_storage_account.storage_account.primary_blob_endpoint
}

output "primary_access_key" {
  description = "The primary access key for the storage account."
  value       = azurerm_storage_account.storage_account.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The connection string associated with the primary location."
  value       = azurerm_storage_account.storage_account.primary_connection_string
  sensitive   = true
}

output "account_tier" {
  description = "The Tier of the Storage Account."
  value       = azurerm_storage_account.storage_account.account_tier
}

output "account_replication_type" {
  description = "The Replication Type of the Storage Account."
  value       = azurerm_storage_account.storage_account.account_replication_type
}

output "account_kind" {
  description = "The Kind of Storage Account."
  value       = azurerm_storage_account.storage_account.account_kind
}

output "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled?"
  value       = azurerm_storage_account.storage_account.is_hns_enabled
}

output "private_endpoint" {
  description = "The private endpoint configuration if enabled"
  value       = azurerm_private_endpoint.storage_pe
}