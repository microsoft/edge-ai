/*
 * Optional Variables
 */

variable "should_create_event_hubs" {
  description = "Whether to create the Event Hubs resources."
  type        = bool
  default     = true
}

variable "should_create_event_grid" {
  description = "Whether to create the Event Grid resources."
  type        = bool
  default     = true
}

# Event Hub configuration parameters
variable "event_hub_capacity" {
  description = "Specifies the Capacity / Throughput Units for Event Hub namespace."
  type        = number
  default     = 1
}

variable "event_hub_message_retention" {
  description = "Specifies the number of days to retain events for Event Hub, from 1 to 7 days."
  type        = number
  default     = 1
}

variable "event_hub_partition_count" {
  description = "Specifies the number of partitions for Event Hub. Valid values are from 1 to 32."
  type        = number
  default     = 1
}

# Event Grid configuration parameters
variable "event_grid_capacity" {
  description = "Specifies the Capacity / Throughput Units for Event Grid namespace."
  type        = number
  default     = 1
}

variable "event_grid_max_client_sessions" {
  description = "Specifies the maximum number of client sessions per authentication name."
  type        = number
  default     = 8
}

variable "event_grid_topic_name" {
  description = "Topic template name to create in the Event Grid namespace."
  type        = string
  default     = "default"
}
