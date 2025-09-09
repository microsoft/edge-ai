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
