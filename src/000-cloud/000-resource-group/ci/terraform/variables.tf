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

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Optional Variables for Existing Resource Group
 */

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = null
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

