variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z][-a-zA-Z0-9]*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes, and must start with an alphabetic character."
  }
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number (001, 002, etc.)."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "description" {
  type        = string
  description = "Description for the AzureML Registry"
}

variable "should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the registry"
}

variable "storage_account" {
  type = object({
    id   = string
    name = string
  })
  description = "Storage account from cloud data component"
}

variable "acr" {
  type = object({
    id   = string
    name = string
  })
  description = "Azure Container Registry from cloud ACR component"
}

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the registry"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the private endpoint"
}

variable "api_dns_zone_name" {
  type        = string
  description = "Name of the privatelink.api.azureml.ms DNS zone (shared with workspace)"
}
