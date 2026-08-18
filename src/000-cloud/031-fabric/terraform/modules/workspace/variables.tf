variable "workspace_display_name" {
  description = "The display name of the workspace"
  type        = string
}

variable "workspace_description" {
  type        = string
  description = "The description of the Microsoft Fabric workspace"
}

variable "capacity_id" {
  type        = string
  description = "The capacity ID for the workspace"
}

variable "skip_capacity_state_validation" {
  type        = bool
  description = "When true, skips validation of Fabric capacity state during workspace provisioning. Useful for non-production environments where capacity may be paused."
}
