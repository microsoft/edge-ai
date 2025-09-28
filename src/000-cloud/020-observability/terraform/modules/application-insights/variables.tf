/*
 * Resource Naming Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance_suffix" {
  type        = string
  description = "Instance suffix for naming resources: fn, web, api, etc."
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics Workspace to associate with Application Insights."
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

variable "internet_ingestion_enabled" {
  type        = bool
  description = "Should the Application Insights support ingestion over the Public Internet."
  default     = true
}

variable "internet_query_enabled" {
  type        = bool
  description = "Should the Application Insights support querying over the Public Internet."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}
