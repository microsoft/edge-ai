variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = null
}

variable "resource_prefix" {
  type = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
  description = "Prefix for all resources in this module"
}

/*
 * Fabric Resource Names - Optional
 */

variable "fabric_workspace_name" {
  type        = string
  description = "The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

/*
 * Fabric Configuration - Optional
 */

variable "should_create_fabric_capacity" {
  description = "Whether to create a new Fabric capacity or use an existing one."
  type        = bool
  default     = false
}

variable "should_create_fabric_eventhouse" {
  description = "Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios."
  type        = bool
  default     = false
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse."
  default     = false
}

variable "should_create_fabric_workspace" {
  description = "Whether to create a new Microsoft Fabric workspace or use an existing one."
  type        = bool
  default     = false
}
