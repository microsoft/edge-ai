variable "eventstream_display_name" {
  description = "The display name of the event stream"
  type        = string
}

variable "eventstream_description" {
  description = "The description of the event stream"
  type        = string
}

variable "workspace_id" {
  description = "The ID of the workspace where the event stream will be created"
  type        = string
}

variable "lakehouse_id" {
  description = "The ID of the lakehouse where data will be stored"
  type        = string
}

variable "eventhub_endpoint" {
  description = "The Azure Eventhub endpoint to use as a source"
  type        = string
}
