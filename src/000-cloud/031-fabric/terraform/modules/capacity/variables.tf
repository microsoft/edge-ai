variable "name" {
  description = "The name of the Fabric capacity."
  type        = string
}

variable "location" {
  description = "The Azure region in which to create the Fabric capacity."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Fabric capacity."
  type        = string
}

variable "admin_members" {
  description = "List of AAD object IDs for Fabric capacity administrators."
  type        = list(string)
  default     = []
}

variable "sku" {
  description = "The SKU name for the Fabric capacity."
  type        = string
  default     = "F2"
}

variable "tags" {
  description = "Tags to apply to the Fabric capacity."
  type        = map(string)
  default     = {}
}
