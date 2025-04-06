variable "key_vault_name" {
  description = "The name of the Key Vault for Secret Sync Extension. (Otherwise, 'kv-{var.resource_prefix}-{var.environment}-{var.instance}'"
  type        = string
}

variable "key_vault_admin_principal_id" {
  description = "The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault."
  type        = string
}
