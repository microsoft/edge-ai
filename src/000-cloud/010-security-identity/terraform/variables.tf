/*
 * Key Vault - Optional
 */

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "key_vault_admin_principal_id" {
  description = "The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault."
  type        = string
  default     = null
}

variable "should_use_current_user_key_vault_admin" {
  description = "Whether to give the current user the Key Vault Secrets Officer Role."
  type        = bool
  default     = true
}

variable "should_create_key_vault" {
  description = "Whether to create the Key Vault."
  type        = bool
  default     = true
}

variable "should_enable_public_network_access" {
  description = "Whether to enable public network access for the Key Vault"
  type        = bool
  default     = true
}

/*
 * Key Vault Private Endpoint - Optional
 */

variable "should_create_key_vault_private_endpoint" {
  description = "Whether to create a private endpoint for the Key Vault."
  type        = bool
  default     = false
}

variable "key_vault_private_endpoint_subnet_id" {
  description = "The ID of the subnet where the Key Vault private endpoint will be created. Required if should_create_key_vault_private_endpoint is true."
  type        = string
  default     = null
}

variable "key_vault_virtual_network_id" {
  description = "The ID of the virtual network to link to the Key Vault private DNS zone. Required if should_create_key_vault_private_endpoint is true."
  type        = string
  default     = null
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
    - skip
EOF
  type        = string
  default     = "id"

  validation {
    condition     = contains(["id", "sp", "skip"], var.onboard_identity_type)
    error_message = "Only ['id', 'sp', 'skip'] allowed for 'onboard_identity_type'"
  }
}

variable "should_create_identities" {
  description = "Whether to create the identities used for Arc Onboarding, Secret Sync, and AIO."
  type        = bool
  default     = true
}

variable "should_create_aks_identity" {
  description = "Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones."
  type        = bool
  default     = false
}

variable "should_create_secret_sync_identity" {
  description = "Whether to create a user-assigned identity for Secret Sync Extension."
  type        = bool
  default     = true
}

variable "should_create_aio_identity" {
  description = "Whether to create a user-assigned identity for Azure IoT Operations."
  type        = bool
  default     = true
}

variable "should_create_ml_workload_identity" {
  description = "Whether to create a user-assigned identity for AzureML workloads."
  type        = bool
  default     = false
}
