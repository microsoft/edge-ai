variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

variable "capacity_id" {
  type        = string
  description = "The capacity ID for the Fabric workspace"
  default     = null
}

variable "should_create_fabric_workspace" {
  description = "Whether to create a new Microsoft Fabric workspace or use an existing one"
  type        = bool
  default     = false
}

variable "should_create_fabric_eventstream" {
  description = "Whether to create a new Fabric EventStream"
  type        = bool
  default     = false
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse"
  default     = false
}

variable "should_create_fabric_capacity" {
  description = "Whether to create a new Fabric capacity or use an existing one"
  type        = bool
  default     = false
}
