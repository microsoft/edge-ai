variable "lakehouse_display_name" {
  description = "The display name of the lakehouse"
  type        = string
}

variable "lakehouse_description" {
  type        = string
  description = "The description of the Microsoft Fabric lakehouse"
}

variable "workspace_id" {
  type        = string
  description = "The ID of the workspace where the lakehouse will be created"
}
