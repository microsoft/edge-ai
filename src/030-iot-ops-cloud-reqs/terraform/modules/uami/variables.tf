variable "location" {
  type        = string
  description = "Location for all resources in this module"
  validation {
    condition     = length(var.location) > 0
    error_message = "Location name must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name must not be empty."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault to use by the Secret Sync Extension"
}
