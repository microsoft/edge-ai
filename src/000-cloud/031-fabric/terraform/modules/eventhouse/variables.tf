variable "eventhouse_display_name" {
  description = "The display name of the eventhouse."
  type        = string
}

variable "eventhouse_description" {
  description = "The description of the eventhouse."
  type        = string
}

variable "workspace_id" {
  description = "The ID of the workspace where the eventhouse will be created."
  type        = string
}

variable "additional_kql_databases" {
  type = map(object({
    display_name = string
    description  = string
  }))
  description = "Additional KQL databases to create within the eventhouse."
  default     = {}
}
