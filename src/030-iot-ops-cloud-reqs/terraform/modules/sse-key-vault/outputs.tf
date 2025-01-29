output "key_vault" {
  value = {
    name = local.key_vault_name
    id   = local.key_vault_id
  }
}
