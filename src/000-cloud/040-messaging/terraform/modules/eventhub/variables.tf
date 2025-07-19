variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "aio_uami_principal_id" {
  type        = string
  description = "Principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}

variable "capacity" {
  description = "Specifies the Capacity / Throughput Units for a Standard SKU namespace."
  type        = number
  validation {
    condition     = var.capacity >= 1 && var.capacity <= 20
    error_message = "Capacity must be between 1 and 20."
  }
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
}
