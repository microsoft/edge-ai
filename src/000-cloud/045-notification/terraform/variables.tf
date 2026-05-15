/*
 * Optional Variables
 */

variable "close_failure_message" {
  type        = string
  description = "HTTP response text when session close fails. Otherwise, 'Failed to close session'"
  default     = "Failed to close session"
}

variable "close_not_found_message" {
  type        = string
  description = "HTTP response text when no active session is found. Otherwise, 'No active session found'"
  default     = "No active session found"
}

variable "close_purpose" {
  type        = string
  description = "Purpose label for the close Logic App name. Otherwise, 'close'"
  default     = "close"
}

variable "close_success_message" {
  type        = string
  description = "HTTP response text when session is closed. Otherwise, 'Session closed'"
  default     = "Session closed"
}

variable "eventhub_consumer_group" {
  type        = string
  description = "Consumer group for Event Hub trigger. Otherwise, '$Default'"
  default     = "$Default"
}

variable "maximum_events_count" {
  type        = number
  description = "Maximum number of events to retrieve per trigger execution. Otherwise, 50"
  default     = 50
}

variable "notification_purpose" {
  type        = string
  description = "Purpose label for the notification Logic App name. Otherwise, 'notify'"
  default     = "notify"
}

variable "polling_interval" {
  type        = number
  description = "Polling interval in seconds for Event Hub trigger. Otherwise, 5"
  default     = 5
}

variable "should_assign_roles" {
  type        = bool
  description = "Whether to create role assignments for the Logic App managed identity"
  default     = true
}

variable "table_name" {
  type        = string
  description = "Azure Table Storage table name for session state tracking. Otherwise, 'notifications'"
  default     = "notifications"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in this module"
  default     = {}
}

variable "teams_post_location" {
  type        = string
  description = "Teams posting location type for the notification message. Otherwise, 'Group chat'"
  default     = "Group chat"
}
