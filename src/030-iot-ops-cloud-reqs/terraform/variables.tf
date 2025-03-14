variable "sse_key_vault_name" {
  type        = string
  description = "The name of the Key Vault for Secret Sync Extension. (Otherwise, 'kv-{var.resource_prefix}-{var.environment}-{var.instance}'"
  default     = null
}
