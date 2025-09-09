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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Fabric RTI Variables - Optional
 */

variable "fabric_eventstream_endpoint" {
  type = object({
    bootstrap_server = string
    topic_name       = string
    endpoint_type    = string
  })
  description = "Fabric RTI connection details from EventStream. If provided, creates a Fabric RTI dataflow endpoint."
  default     = null
}

variable "fabric_workspace" {
  type = object({
    id           = string
    display_name = string
  })
  description = "Fabric workspace for RTI resources. Required when fabric_eventstream_endpoint is provided."
  default     = null
}
