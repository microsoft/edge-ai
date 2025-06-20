/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}

/*
 * Optional Variables
 */

variable "cluster_server_machine" {
  type = object({
    id       = string
    location = string
  })
  default = null
}

variable "cluster_node_machine" {
  type = list(object({
    id       = string
    location = string
  }))
  default = null
}

variable "arc_onboarding_principal_ids" {
  type        = list(string)
  description = "The Principal IDs for a pre-existing identity that will be used for onboarding the cluster to Arc."
  default     = null
}

variable "arc_onboarding_identity" {
  description = "The Principal ID for the identity that will be used for onboarding the cluster to Arc."
  type = object({
    principal_id = string
  })
  default = null

  validation {
    condition     = !var.should_assign_roles || anytrue([var.arc_onboarding_identity != null, var.arc_onboarding_sp != null, var.arc_onboarding_principal_ids != null])
    error_message = "Either 'arc_onboarding_identity', 'arc_onboarding_sp', or 'arc_onboarding_principal_ids' required when should_assign_roles is 'true'"
  }

  validation {
    condition     = !var.should_assign_roles || (sum([var.arc_onboarding_identity != null ? 1 : 0, var.arc_onboarding_sp != null ? 1 : 0, var.arc_onboarding_principal_ids != null ? 1 : 0]) <= 1)
    error_message = "Only one of 'arc_onboarding_identity', 'arc_onboarding_sp', or 'arc_onboarding_principal_ids' can be provided"
  }
}

variable "arc_onboarding_sp" {
  type = object({
    client_id     = string
    object_id     = string
    client_secret = string
  })
  sensitive = true
  default   = null
}

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "The Key Vault object containing id, name, and vault_uri properties."
  default     = null

  validation {
    condition     = !var.should_upload_to_key_vault || var.key_vault != null
    error_message = "'key_vault' is required when 'should_upload_to_key_vault' is true"
  }
}

variable "private_key_pem" {
  type        = string
  description = "Private key for onboarding"
  default     = null
}

