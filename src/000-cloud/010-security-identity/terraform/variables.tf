/*
 * Key Vault - Optional
 */

variable "key_vault_name" {
  type        = string
  description = "The resource name for the new Key Vault. (Otherwise, 'kv-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "key_vault_admin_principal_id" {
  description = "The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault."
  type        = string
  default     = null
}

variable "should_use_current_user_key_vault_admin" {
  description = "Whether to give the current user the Key Vault Secrets Officer Role."
  type        = string
  default     = true
}

variable "should_create_key_vault" {
  description = "Whether to create the Key Vault."
  type        = bool
  default     = true
}

/*
 * Identity - Optional
 */

variable "onboard_identity_type" {
  description = <<-EOF
    Identity type to use for onboarding the cluster to Azure Arc.

    Allowed values:

    - id
    - sp
EOF
  type        = string
  default     = "id"

  validation {
    condition     = contains(["id", "sp"], var.onboard_identity_type)
    error_message = "Only ['id', 'sp'] allowed for 'onboard_identity_type'"
  }
}

variable "should_create_identities" {
  description = "Whether to create the identities used for Arc Onboarding, Secret Sync, and AIO."
  type        = bool
  default     = true
}
