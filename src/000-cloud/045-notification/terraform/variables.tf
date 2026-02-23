/*
 * Optional Variables
 */

variable "should_assign_roles" {
  type        = bool
  description = "Whether to create role assignments for the Logic App managed identity"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in this module"
  default     = {}
}

variable "teams_recipient_id" {
  type        = string
  description = "Teams chat or channel thread ID for posting leak detection notifications"
}

variable "teams_post_location" {
  type        = string
  description = "Teams posting location type for the notification message"
  default     = "Group chat"
}
