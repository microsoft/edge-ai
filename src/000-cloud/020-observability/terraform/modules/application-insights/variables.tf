/*
 * Resource Naming Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
}

variable "instance_suffix" {
  type        = string
  description = "Instance suffix for naming resources: fn, web, api, etc."
}

variable "location" {
  type        = string
  description = "Location for all resources in this module."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics Workspace to associate with Application Insights."
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
 * Application Insights Configuration - Optional
 */

variable "application_type" {
  type        = string
  description = "The type of application being monitored."
}

variable "retention_in_days" {
  type        = number
  description = "The retention period in days for Application Insights data."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}
