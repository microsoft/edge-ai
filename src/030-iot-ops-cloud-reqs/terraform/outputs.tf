output "schema_registry_id" {
  value = module.schema_registry.registry_id
}

output "sse_key_vault_name" {
  value = try(module.sse_key_vault[0].key_vault.name, "")
}

output "aio_uami_name" {
  value = module.uami.aio_uami_name
}

output "sse_uami_name" {
  value = module.uami.sse_uami_name
}

output "adr_schema_registry" {
  value = module.schema_registry.adr_schema_registry
}

output "aio_user_assigned_identity" {
  value = module.uami.aio_user_assigned_identity
}

output "sse_key_vault" {
  value = try(module.sse_key_vault[0].key_vault, var.sse_key_vault)
}

output "sse_user_assigned_identity" {
  value = module.uami.sse_user_assigned_identity
}
