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
  description = "Specifies the Capacity / Throughput Units for a Standard SKU namespace. Valid values range from 1 - 40."
  type        = number
  default     = 1
  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40
    error_message = "Capacity must be between 1 and 40."
  }
}

variable "event_grid_max_client_sessions_per_auth_name" {
  description = "Specifies the maximum number of client sessions per authentication name. Valid values are from 3 to 100. This parameter should be greater than the number of dataflows"
  type        = number
  default     = 8
  validation {
    condition     = var.event_grid_max_client_sessions_per_auth_name >= 3 && var.event_grid_max_client_sessions_per_auth_name <= 100
    error_message = "Partition count must be between 1 and 100."
  }
}

variable "topic_name" {
  description = "Topic template name to create in the Event Grid namespace"
  type        = string
  default     = "default"
}
