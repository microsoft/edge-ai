/*
 * Fabric Resource Names - Optional
 */

variable "fabric_workspace_name" {
  type        = string
  description = "The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "fabric_lakehouse_name" {
  description = "The name of the Microsoft Fabric lakehouse. Otherwise, 'lh-{resource_prefix}-{environment}-{instance}'."
  type        = string
  default     = null
}

variable "fabric_eventhouse_name" {
  type        = string
  description = "The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "fabric_capacity_name" {
  description = "The name of the Microsoft Fabric capacity. Otherwise, 'cap-{resource_prefix}-{environment}-{instance}'."
  type        = string
  default     = null
}

/*
 * Fabric Configuration - Optional
 */

variable "additional_kql_databases" {
  type = map(object({
    display_name = string
    description  = string
  }))
  description = "Additional KQL databases to create within the eventhouse."
  default     = {}
}

variable "eventhouse_description" {
  type        = string
  description = "The description of the Microsoft Fabric eventhouse"
  default     = "Eventhouse for real-time analytics of Edge device data"
}

variable "fabric_capacity_admins" {
  description = "List of AAD object IDs for Fabric capacity administrators."
  type        = list(string)
  default     = []
}

variable "fabric_capacity_sku" {
  description = "The SKU name for the Fabric capacity."
  type        = string
  default     = "F2"
}

variable "lakehouse_description" {
  type        = string
  description = "The description of the Microsoft Fabric lakehouse"
  default     = "Lakehouse for storing and analyzing data from Edge devices"
}

variable "should_create_fabric_capacity" {
  description = "Whether to create a new Fabric capacity or use an existing one."
  type        = bool
  default     = false
}

variable "should_create_fabric_eventhouse" {
  description = "Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios."
  type        = bool
  default     = false
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse."
  default     = false
}

variable "should_create_fabric_workspace" {
  description = "Whether to create a new Microsoft Fabric workspace or use an existing one."
  type        = bool
  default     = false
}

variable "workspace_description" {
  type        = string
  description = "The description of the Microsoft Fabric workspace"
  default     = "Microsoft Fabric workspace for the Edge AI Accelerator solution"
}
