output "schema_registry_id" {
  value = module.schema_registry.registry_id
}

output "sse_key_vault_name" {
  value = module.sse_key_vault.key_vault.name
}

output "aio_uami_name" {
  value = module.uami.aio_uami_name
}

output "sse_uami_name" {
  value = module.uami.sse_uami_name
}
