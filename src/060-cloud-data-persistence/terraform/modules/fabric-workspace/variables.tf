variable "workspace_display_name" {
  description = "The display name of the workspace"
  type        = string
}

variable "workspace_description" {
  description = "The description of the workspace"
  type        = string
}

variable "capacity_id" {
  description = "The ID of the premium capacity to assign to the workspace (Run ./scripts/select-fabric-capacity.sh to choose one)"
  type        = string
}