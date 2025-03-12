output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = module.storage_account.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary endpoint for blob service"
  value       = module.storage_account.primary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string of the Storage Account"
  value       = module.storage_account.primary_connection_string
  sensitive   = true
}

output "container_name" {
  description = "The name of the storage container"
  value       = module.data_lake.container_name
}

output "file_share_name" {
  description = "The name of the file share (if created)"
  value       = module.data_lake.file_share_name
}

output "data_lake_filesystem_name" {
  description = "The name of the Data Lake Gen2 filesystem"
  value       = module.data_lake.data_lake_filesystem_name
}