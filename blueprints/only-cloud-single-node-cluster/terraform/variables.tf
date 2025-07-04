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

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. If not provided, a default name will be generated using resource_prefix, environment, and instance."
  default     = null
}

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
  default     = false
}

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create Azure Functions for the cluster"
  default     = false
}
