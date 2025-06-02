/*
 * Resource Naming Parameters - Required
 */

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
 * App Service Plan Configuration - Required
 */

variable "os_type" {
  type        = string
  description = "The operating system type for the App Service Plan."
}

variable "sku_name" {
  type        = string
  description = "The SKU name for the App Service Plan."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}
