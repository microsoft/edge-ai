/*
 * Required Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
  description = "Prefix for all resources in this module"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "should_use_azure_ad_auth" {
  type        = bool
  description = "Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication"
  default     = true
}

variable "azure_ad_config" {
  type = object({
    tenant_id = optional(string)
    audience  = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8")
    issuer    = optional(string)
  })
  description = "Azure AD configuration for VPN Gateway authentication. tenant_id is required when should_use_azure_ad_auth is true. audience defaults to Microsoft-registered app. issuer will default to 'https://sts.windows.net/{tenant_id}/' when not provided"
  default     = {}
}
