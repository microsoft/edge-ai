variable "eventhouse_display_name" {
  description = "The display name of the eventhouse."
  type        = string
}

variable "eventhouse_description" {
  type        = string
  description = "The description of the Microsoft Fabric eventhouse"
}

variable "workspace_id" {
  type        = string
  description = "The ID of the workspace where the lakehouse will be created"
}

variable "additional_kql_databases" {
  type = map(object({
    display_name = string
    description  = string
  }))
  description = "Additional KQL databases to create within the eventhouse."
  default     = {}
}
