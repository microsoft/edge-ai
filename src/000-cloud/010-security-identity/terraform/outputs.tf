output "aio_identity" {
  value = try(module.identity[0].aio_identity, null)
}

output "key_vault" {
  value = try(module.key_vault[0].key_vault, null)
}

output "secret_sync_identity" {
  value = try(module.identity[0].secret_sync_identity, null)
}

output "arc_onboarding_sp" {
  value     = try(module.identity[0].arc_onboarding_sp, null)
  sensitive = true
}

output "arc_onboarding_identity" {
  value = try(module.identity[0].arc_onboarding_identity, null)
}
