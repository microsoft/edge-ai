output "aio_identity" {
  value = try(module.identity[0].aio_identity, null)
}

output "key_vault" {
  value = try(module.key_vault[0].key_vault, null)
}

output "key_vault_private_endpoint" {
  description = "The private endpoint for Key Vault."
  value       = try(module.key_vault[0].private_endpoint, null)
}

output "key_vault_private_dns_zone" {
  description = "The private DNS zone for Key Vault."
  value       = try(module.key_vault[0].private_dns_zone, null)
}

output "secret_sync_identity" {
  value = try(module.identity[0].secret_sync_identity, null)
}

output "ml_workload_identity" {
  description = "The AzureML workload user-assigned identity."
  value       = try(module.identity[0].ml_workload_identity, null)
}

output "arc_onboarding_sp" {
  value     = try(module.identity[0].arc_onboarding_sp, null)
  sensitive = true
}

output "arc_onboarding_identity" {
  value = try(module.identity[0].arc_onboarding_identity, null)
}

output "aks_identity" {
  description = "The AKS user-assigned identity for custom private DNS zone scenarios."
  value       = try(module.identity[0].aks_identity, null)
}
