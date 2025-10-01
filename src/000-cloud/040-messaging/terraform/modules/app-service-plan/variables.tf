/*
 * Resource Naming Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

/*
 * App Service Plan Configuration - Required
 */

variable "os_type" {
  type        = string
  description = "Operating system type (only linux supported)"
}

variable "sku_name" {
  type        = string
  description = "The SKU name for the App Service Plan."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}
