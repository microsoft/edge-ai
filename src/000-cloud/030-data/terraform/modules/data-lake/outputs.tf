output "blob_container_name" {
  description = "The name for the Data Lake Blob Container."
  value       = azurerm_storage_container.data_lake.name
}

output "blob_container_id" {
  description = "The ID for the Data Lake Blob Container."
  value       = azurerm_storage_container.data_lake.id
}

output "file_share_name" {
  description = "The name for the Data Lake File Share."
  value       = try(azurerm_storage_share.data_lake[0].name, null)
}

output "filesystem_name" {
  description = "The name for the Data Lake Gen2 Filesystem."
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake.name
}
