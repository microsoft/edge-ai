variable "resource_group" {
  description = "Resource group object containing name and id where resources will be deployed"
  type = object({
    name     = string
    location = string
  })
}

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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
}
