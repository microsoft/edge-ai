variable "environment" {
  description = "Environment for all resources in this module: dev, test, or prod."
  type        = string
}

variable "location" {
  description = "Location for all resources in this module."
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources in this module."
  type        = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z][-a-zA-Z0-9]*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes, and must start with an alphabetic character."
  }
}

variable "instance" {
  description = "Instance identifier for naming resources: 001, 002, etc."
  type        = string
  default     = "001"
}
