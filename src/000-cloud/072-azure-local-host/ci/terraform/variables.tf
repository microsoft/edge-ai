variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing Azure Local resources"
  default     = null
}

variable "custom_locations_oid" {
  type        = string
  description = "Custom Location resource ID for Azure Local deployment"
}

variable "logical_network_name" {
  type        = string
  description = "Name of the Azure Local logical network used for cluster infrastructure networking"
  default     = null
}

variable "logical_network_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the Azure Local logical network"
  default     = null
}

