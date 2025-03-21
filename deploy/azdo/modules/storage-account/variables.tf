variable "resource_group" {
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
  description = "Instance identifier for naming resources: 001, 002, etc..."
}

variable "storage_account" {
  type = object({
    name             = string
    tier             = string
    replication_type = string
  })
  default = {
    name             = ""
    tier             = "Standard"
    replication_type = "LRS"
  }
  description = "Storage account name, tier and replication_type for the Storage Account to be created. Defaults to a randomly generated name, \"Standard\" tier and \"LRS\" replication_type"
}