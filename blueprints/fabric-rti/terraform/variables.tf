/**
 * # Fabric RTI Minimal Blueprint Variables
 *
 * Variables for the fabric-rti-minimal blueprint.
 * References existing infrastructure via data sources to deploy only Fabric RTI components.
 */

/*
 * Core Variables - Required
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

/*
 * Existing Resource Names - Required for Data Sources
 */

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = null
}

variable "fabric_workspace_name" {
  type        = string
  description = "The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "fabric_eventhouse_name" {
  type        = string
  description = "The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "aio_identity_name" {
  type        = string
  description = "Name of the existing AIO user-assigned managed identity. Otherwise, 'id-{resource_prefix}-{environment}-aio-{instance}'."
  default     = null
}

variable "aio_instance_name" {
  type        = string
  description = "Name of the existing AIO instance. Otherwise, 'arck-{resource_prefix}-{environment}-{instance}-ops-instance'."
  default     = null
}

variable "custom_location_name" {
  type        = string
  description = "Name of the existing custom location. Otherwise, 'arck-{resource_prefix}-{environment}-{instance}-cl'."
  default     = null
}

/*
 * Fabric Configuration - Optional
 */

variable "should_create_fabric_eventhouse" {
  description = "Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios."
  type        = bool
  default     = true
}

/*
 * EventStream Configuration - Optional
 */

variable "eventstream_table_name" {
  type        = string
  description = "Name of the Eventhouse table for data ingestion."
  default     = null
}

variable "eventhouse_kql_database_name" {
  type        = string
  description = "Name of the Eventhouse KQL Database. (default, Eventhouse name)"
  default     = null
}

variable "should_create_eventgrid_dataflows" {
  type        = bool
  description = "Whether to create EventGrid dataflows in the edge messaging component"
  default     = false
}

variable "should_create_eventhub_dataflows" {
  type        = bool
  description = "Whether to create EventHub dataflows in the edge messaging component"
  default     = false
}
