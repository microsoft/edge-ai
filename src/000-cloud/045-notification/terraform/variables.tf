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

variable "teams_webhook_secret_name" {
  type        = string
  description = "Name of the Key Vault secret containing the Teams Incoming Webhook URL"
  default     = "teams-webhook-url"
}
