variable "secret_sync_identity" {
  type = object({
    principal_id = string
  })
}

variable "secret_sync_key_vault" {
  description = "Azure Key Vault ID to use with Secret Sync Extension."
  type = object({
    id = string
  })
}
