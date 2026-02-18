output "storage_container_name" {
  description = "The name of the created storage container"
  value       = azurerm_storage_container.media.name
}

output "role_assignment_id" {
  description = "The resource ID of the ACSA role assignment"
  value       = azurerm_role_assignment.acsa_blob_data_owner.id
}
