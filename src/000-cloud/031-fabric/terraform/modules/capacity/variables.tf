variable "name" {
  description = "The name of the Fabric capacity."
  type        = string
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "admin_members" {
  description = "List of AAD object IDs for Fabric capacity administrators."
  type        = list(string)
  default     = []
}

variable "sku" {
  type        = string
  description = "SKU name for the resource"
  default     = "F2"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
