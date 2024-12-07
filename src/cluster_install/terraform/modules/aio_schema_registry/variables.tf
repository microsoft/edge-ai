variable "location" {
  type        = string
  description = "Location for all resources in this module"
  validation {
    condition     = length(var.location) > 0
    error_message = "Location name must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name must not be empty."
  }
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

variable "resource_prefix" {
  type        = string
  description = "Prefix for the registry and registry namespace created in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must start and end with letters or numbers. Only '-', letters, or numbers are allowed."
  }
}
