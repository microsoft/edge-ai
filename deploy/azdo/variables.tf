/*
 * Resource Group Settings
 */
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create or use."
  default     = null
}

/*
 * Core Settings - Required
 */
variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module."
}

/*
 * Instance Settings - Optional
 */
variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc."
  default     = "001"
}
