variable "resource_group" {
  description = "Resource group for all resources in this module."
  type = object({
    name     = string
    location = string
  })
}

variable "snet_acr" {
  description = "Subnet for the Azure Container Registry private endpoint."
  type = object({
    id = string
  })
}

variable "vnet" {
  description = "Virtual Network for Container Registry Private DNS Zone."
  type = object({
    id = string
  })
}

variable "sku" {
  type        = string
  description = "SKU for the Azure Container Registry. Options are Basic, Standard, Premium. Default is Premium because of the need for private endpoints."
  default     = "Premium"
}

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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc."
}
