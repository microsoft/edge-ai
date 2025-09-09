variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource_prefix}-{environment}-{instance}'"
}

variable "key_vault_admin_principal_id" {
  description = "The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault."
  type        = string
}
