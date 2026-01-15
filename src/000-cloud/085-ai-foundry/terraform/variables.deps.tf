/*
 * Inter-component dependency variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = optional(string)
    location = optional(string)
  })
  description = "Resource group object from 000-resource-group component"
}

variable "key_vault" {
  type = object({
    id          = optional(string)
    name        = optional(string)
    vault_uri   = optional(string)
    tenant_id   = optional(string)
    key_name    = optional(string)
    key_version = optional(string)
  })
  default     = null
  description = "Key Vault object for customer-managed key encryption. Required when should_enable_cmk_encryption is true"
}
