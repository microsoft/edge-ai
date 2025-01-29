variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
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
  description = "Specifies the Capacity / Throughput Units for a Standard SKU namespace. Valid values range from 1 - 20."
  type        = number
  default     = 1
  validation {
    condition     = var.capacity >= 1 && var.capacity <= 20
    error_message = "Capacity must be between 1 and 20."
  }
}

variable "message_retention" {
  description = "Specifies the number of days to retain events for this Event Hub, from 1 to 7 days."
  type        = number
  default     = 1
  validation {
    condition     = var.message_retention >= 1 && var.message_retention <= 7
    error_message = "Message retention must be between 1 and 7 days."
  }
}

variable "partition_count" {
  description = "Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32."
  type        = number
  default     = 1
  validation {
    condition     = var.partition_count >= 1 && var.partition_count <= 32
    error_message = "Partition count must be between 1 and 32."
  }
}
