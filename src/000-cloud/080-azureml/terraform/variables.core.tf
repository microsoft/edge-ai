/*
 * Core variables consistent across all components
 */

variable "environment" {
  type        = string
  description = "The environment for the deployment."
}

variable "instance" {
  type        = string
  description = "Instance identifier for the deployment."
  default     = "001"
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names."

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.resource_prefix))
    error_message = "Resource prefix must be 1-10 characters, lowercase letters and numbers only."
  }
}
