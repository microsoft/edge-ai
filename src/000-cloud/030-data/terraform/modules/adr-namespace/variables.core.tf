/*
 * Required Variables
 */

variable "adr_namespace_name" {
  type        = string
  description = "The name of the ADR namespace. Must be 3-64 characters, lowercase letters and numbers only, with optional hyphens."
  validation {
    condition     = length(var.adr_namespace_name) >= 3 && length(var.adr_namespace_name) <= 64 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.adr_namespace_name))
    error_message = "ADR namespace name must be 3-64 characters, lowercase letters and numbers only, with optional hyphens (cannot start or end with hyphen)."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}
