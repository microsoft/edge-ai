/*
 * Core variables consistent across all components
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, or prod."
  }
}

variable "instance" {
  type        = string
  default     = "001"
  description = "Instance identifier for naming resources: 001, 002, etc"
  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit string (e.g., 001, 002)."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
  validation {
    condition     = length(var.location) > 0
    error_message = "Location must not be empty."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z][-a-zA-Z0-9]*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes, and must start with an alphabetic character."
  }
}
