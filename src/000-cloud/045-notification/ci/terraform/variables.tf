/*
 * Required Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "eventhub_name" {
  type        = string
  description = "Name of the Event Hub to subscribe to for events"
  default     = "evh-aio-sample"
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

variable "teams_recipient_id" {
  type        = string
  description = "Teams chat or channel thread ID for posting event notifications"
  default     = "19:mock-thread-id@thread.v2"
}
