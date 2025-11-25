variable "name" {
  description = "The name of the Fabric capacity."
  type        = string
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 63 && can(regex("^[a-z][a-z0-9]*$", var.name))
    error_message = "Fabric capacity name must be between 3 and 63 characters, contain only lowercase letters and numbers, and must start with a lowercase letter."
  }
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
  description = <<-EOT
    List of user principal names (UPNs) or Azure AD object IDs for Fabric capacity administrators.
    For users, provide UPN (<user@domain.com>) or Object ID.
    For service principals, provide Application ID or Object ID.
    At least one administrator is required.
  EOT
  type        = list(string)
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
