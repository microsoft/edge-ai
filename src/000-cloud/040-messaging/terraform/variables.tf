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

variable "should_create_azure_functions" {
  description = "Whether to create the Azure Functions resources including App Service Plan."
  type        = bool
  default     = false
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

# App Service Plan configuration parameters
variable "app_service_plan_os_type" {
  description = "The operating system type for the App Service Plan."
  type        = string
  default     = "Linux"
}

variable "app_service_plan_sku_name" {
  description = "The SKU name for the App Service Plan."
  type        = string
  default     = "B1"
}

# Azure Functions configuration parameters
variable "function_app_settings" {
  description = "A map of key-value pairs for App Settings."
  type        = map(string)
  default     = {}
}

variable "function_cors_allowed_origins" {
  description = "A list of origins that should be allowed to make cross-origin calls."
  type        = list(string)
  default     = ["*"]
}

variable "function_cors_support_credentials" {
  description = "Whether CORS requests with credentials are allowed."
  type        = bool
  default     = false
}

variable "function_node_version" {
  description = "The version of Node.js to use."
  type        = string
  default     = "18"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
