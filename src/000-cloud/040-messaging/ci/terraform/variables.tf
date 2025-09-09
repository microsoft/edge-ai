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

variable "eventhubs" {
  description = <<-EOF
    Per-Event Hub configuration. Keys are Event Hub names.

    - **Message retention**: Specifies the number of days to retain events for this Event Hub, from 1 to 7.
    - **Partition count**: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32.
    - **Consumer group user metadata**: A placeholder to store user-defined string data with maximum length 1024.
      It can be used to store descriptive data, such as list of teams and their contact information,
      or user-defined configuration settings.
  EOF
  type = map(object({
    message_retention = optional(number, 1)
    partition_count   = optional(number, 1)
    consumer_groups = optional(map(object({
      user_metadata = optional(string, null)
    })), {})
  }))
  default = { "evh-aio-sample" = {} }
}
