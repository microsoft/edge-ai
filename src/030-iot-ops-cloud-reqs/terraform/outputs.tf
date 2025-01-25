output "schema_registry_id" {
  value = module.schema_registry.registry_id
}

output "sse_key_vault_name" {
  value = module.sse_key_vault.key_vault.name
}

output "sse_key_vault_id" {
  value = module.sse_key_vault.key_vault.id
}
