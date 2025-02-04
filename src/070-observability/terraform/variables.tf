/*
 * Optional Variables
 */

variable "grafana_admin_principal_id" {
  description = "Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users"
  type        = string
  default     = null
}

variable "grafana_major_version" {
  description = "Major version of grafana to use"
  type        = string
  default     = "10"
}

variable "log_retention_in_days" {
  description = "Duration to retain logs in log analytics"
  type        = number
  default     = 30
}

variable "daily_quota_in_gb" {
  description = "Daily quota to write logs in log analytics"
  type        = number
  default     = 10
}
