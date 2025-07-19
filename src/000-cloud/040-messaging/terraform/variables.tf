/*
 * Optional Variables
 */

variable "should_create_eventhub" {
  description = "Whether to create the Event Hubs resources."
  type        = bool
  default     = true
}

variable "should_create_eventgrid" {
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
variable "eventhub_capacity" {
  description = "Specifies the Capacity / Throughput Units for Event Hub namespace."
  type        = number
  default     = 1
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

# Event Grid configuration parameters
variable "eventgrid_capacity" {
  description = "Specifies the Capacity / Throughput Units for Event Grid namespace."
  type        = number
  default     = 1
}

variable "eventgrid_max_client_sessions" {
  description = "Specifies the maximum number of client sessions per authentication name."
  type        = number
  default     = 8
}

variable "eventgrid_topic_name" {
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
