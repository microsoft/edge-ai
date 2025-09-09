/*
 * Required Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
  description = "Prefix for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "fabric_workspace_name" {
  type        = string
  description = "The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "fabric_eventhouse_name" {
  type        = string
  description = "The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource_prefix}-{environment}-{instance}'"
  default     = null
}
