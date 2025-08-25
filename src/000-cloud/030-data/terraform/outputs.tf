output "storage_account" {
  description = "The new Storage Account resource."
  value       = module.storage_account.storage_account
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

output "schema_registry" {
  description = "The new ADR Schema Registry resource."
  value       = try(module.schema_registry[0].schema_registry, null)
}

output "adr_namespace" {
  description = "The Azure Device Registry namespace resource."
  value       = try(module.adr_namespace[0].adr_namespace, null)
}
