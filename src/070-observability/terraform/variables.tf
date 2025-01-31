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
  default     = "001"
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "shared_resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "grafana_admin_principal_id" {
  description = "Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users"
  type        = string
  default     = null
}

variable "grafana_major_version" {
  description = "Major version of grafana to use"
  type        = string
  default     = "10"
}

variable "log_retention_in_days" {
  description = "Duration to retain logs in log analytics"
  type        = number
  default     = 30
}

variable "daily_quota_in_gb" {
  description = "Daily quota to write logs in log analytics"
  type        = number
  default     = 10
}
