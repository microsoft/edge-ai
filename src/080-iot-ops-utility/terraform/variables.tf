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

variable "connected_cluster_name" {
  type        = string
  description = "The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource_prefix}-arc')"
  default     = null
}

variable "azure_monitor_workspace_name" {
  type        = string
  description = "The name of the Azure Monitor resource. (Otherwise, 'azmon-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Azure Log Analytics resource. (Otherwise, 'log-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "grafana_name" {
  type        = string
  description = "The name of the Azure Managed Grafana resource. (Otherwise, 'amg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}
