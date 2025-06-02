/*
 * Resource Naming Parameters - Required
 */

variable "app_service_plan" {
  type = object({
    id      = string
    os_type = string
  })
  description = "The App Service Plan object containing id and os_type."
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc."
}

variable "location" {
  type        = string
  description = "Location for all resources in this module."
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
}

/*
 * Function App Configuration - Required
 */

variable "app_settings" {
  type        = map(string)
  description = "A map of key-value pairs for App Settings."
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "A list of origins that should be allowed to make cross-origin calls."
}

variable "cors_support_credentials" {
  type        = bool
  description = "Whether CORS requests with credentials are allowed."
}

variable "node_version" {
  type        = string
  description = "The version of Node.js to use."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}
