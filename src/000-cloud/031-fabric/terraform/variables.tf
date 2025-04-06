/*
 * Fabric - Optional
 */

variable "should_create_fabric_eventstream" {
  description = "Whether to create a new Fabric EventStream"
  type        = bool
  default     = false

  validation {
    condition = var.should_create_fabric_eventstream ? (
    var.should_create_fabric_lakehouse && var.eventhub_endpoint != null) : true
    error_message = "'should_create_fabric_eventstream' requires both 'should_create_fabric_lakehouse=true' and 'eventhub_endpoint' to be provided."
  }
}

variable "eventstream_description" {
  description = "The description of the Microsoft Fabric event stream"
  type        = string
  default     = "Event Stream for real-time ingestion of Edge device data"
}

variable "eventhub_endpoint" {
  description = "The endpoint of the Eventhub to connect to the EventStream"
  type        = string
  default     = null
}

variable "workspace_description" {
  description = "The description of the Microsoft Fabric workspace"
  type        = string
  default     = "Microsoft Fabric workspace for the Edge AI Accelerator solution"
}

variable "lakehouse_description" {
  description = "The description of the Microsoft Fabric lakehouse"
  type        = string
  default     = "Lakehouse for storing and analyzing data from Edge devices"
}

variable "should_create_fabric_workspace" {
  description = "Whether to create a new Microsoft Fabric workspace or use an existing one"
  type        = bool
  default     = false
}

variable "existing_fabric_workspace_id" {
  description = "The ID of an existing Microsoft Fabric workspace to use (if should_create_fabric_workspace=false)"
  type        = string
  default     = null
}

variable "capacity_id" {
  description = "ID of the Microsoft Fabric capacity to use. Leave empty to use free tier."
  type        = string
  default     = null
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse"
  default     = false
  validation {
    condition = var.should_create_fabric_lakehouse ? anytrue(
    [var.should_create_fabric_workspace, var.existing_fabric_workspace_id != null]) : true
    error_message = "To create a lakehouse, you must either create a workspace or provide an existing workspace ID."
  }
}

variable "should_create_fabric_capacity" {
  description = "Whether to create a new Fabric capacity or use an existing one"
  type        = bool
  default     = false
}

variable "fabric_capacity_id" {
  description = "The ID of an existing Fabric capacity to use (required when create_fabric_capacity=false)"
  type        = string
  default     = null
}

variable "fabric_capacity_sku" {
  description = "The SKU name for the Fabric capacity"
  type        = string
  default     = "F2"
}

variable "fabric_capacity_admins" {
  description = "List of AAD object IDs for Fabric capacity administrators"
  type        = list(string)
  default     = []
}
