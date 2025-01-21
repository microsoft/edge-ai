variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected Arc cluster"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0
    error_message = "Prefix must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name must not be empty."
  }
}

variable "aio_extension_name" {
  type        = string
  description = "The name of the Azure IoT Operations Platform Arc extension"
}

variable "sku" {
  description = "Defines which tier to use. Valid options are Basic and Standard."
  default     = "Basic"
  type        = string
  validation {
    condition     = var.sku == "Basic" || var.sku == "Standard"
    error_message = "SKU must be either Basic or Standard."
  }
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
