variable "create_capacity" {
  description = "Boolean flag to determine whether to create a new Fabric capacity or use an existing one"
  type        = bool
  default     = true
}

variable "capacity_id" {
  description = "The ID of an existing Fabric capacity to use (required when create_capacity=false)"
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the Fabric capacity"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Fabric capacity"
  type        = string
}

variable "location" {
  description = "The Azure region in which to create the Fabric capacity"
  type        = string
}

variable "sku" {
  description = "The SKU name for the Fabric capacity"
  type        = string
  default     = "F2"
  validation {
    condition     = contains(["F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512"], var.sku)
    error_message = "The SKU must be one of: F2, F4, F8, F16, F32, F64, F128, F256, F512"
  }
}

variable "admin_members" {
  description = "List of AAD object IDs for Fabric capacity administrators"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the Fabric capacity"
  type        = map(string)
  default     = {}
}
