output "container_name" {
  description = "The name of the storage container"
  value       = azurerm_storage_container.container.name
}

output "container_id" {
  description = "The ID of the storage container"
  value       = azurerm_storage_container.container.id
}

output "file_share_name" {
  description = "The name of the file share (if created)"
  value       = var.create_file_share ? azurerm_storage_share.file_share[0].name : null
}

output "data_lake_filesystem_name" {
  description = "The name of the Data Lake Gen2 filesystem"
  value       = azurerm_storage_data_lake_gen2_filesystem.data_lake.name
}

output "role_assignments_owner" {
  description = "The Storage Blob Data Owner role assignments"
  value       = azurerm_role_assignment.data_lake_owner
}

output "role_assignments_contributor" {
  description = "The Storage Blob Data Contributor role assignments"
  value       = azurerm_role_assignment.data_lake_contributor
}