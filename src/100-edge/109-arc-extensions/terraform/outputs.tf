output "cert_manager_extension_id" {
  description = "The resource ID of the cert-manager extension."
  value       = try(module.cert_manager_extension[0].extension.id, null)
}

output "cert_manager_extension_name" {
  description = "The name of the cert-manager extension."
  value       = try(module.cert_manager_extension[0].extension.name, null)
}

output "container_storage_extension_id" {
  description = "The resource ID of the Azure Container Storage extension."
  value       = try(module.container_storage_extension[0].extension.id, null)
}

output "container_storage_extension_name" {
  description = "The name of the Azure Container Storage extension."
  value       = try(module.container_storage_extension[0].extension.name, null)
}

output "cert_manager_extension" {
  description = "Self-contained cert_manager object (id, name, enabled, version, train) or null if not deployed"
  value       = try(module.cert_manager_extension[0].cert_manager, null)
}

output "container_storage_extension" {
  description = "Self-contained container_storage object (id, name, enabled, version, train) or null if not deployed"
  value       = try(module.container_storage_extension[0].container_storage, null)
}
