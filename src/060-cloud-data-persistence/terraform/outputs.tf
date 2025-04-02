output "storage_account_id" {
  description = "The resource ID for the Storage Account."
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "The name for the Storage Account."
  value       = module.storage_account.name
}

output "data_lake_blob_container_name" {
  description = "The name for the Data Lake Blob Container."
  value       = try(module.data_lake[0].blob_container_name, null)
}

output "data_lake_file_share_name" {
  description = "The name for the Data Lake File Share."
  value       = try(module.data_lake[0].file_share_name, null)
}

output "data_lake_filesystem_name" {
  description = "The name for the Data Lake Gen2 Filesystem."
  value       = try(module.data_lake[0].filesystem_name, null)
}

output "fabric_capacity" {
  description = "Fabric capacity details"
  value = {
    id   = module.fabric_capacity.capacity_id
    name = module.fabric_capacity.capacity_name
    sku  = module.fabric_capacity.capacity_sku
  }
}