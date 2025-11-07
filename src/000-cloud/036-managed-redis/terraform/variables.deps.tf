/*
 * Dependency Variables
 */

variable "managed_identity" {
  description = "User Assigned Managed Identity for Entra ID authentication. Required when access_keys_authentication_enabled is false"
  type = object({
    id = string
  })
  default = null
}

variable "private_endpoint_subnet" {
  description = "Subnet for private endpoint deployment. Required when should_enable_private_endpoint is true"
  type = object({
    id = string
  })
  default = null

  validation {
    condition     = var.should_enable_private_endpoint ? var.private_endpoint_subnet != null : true
    error_message = "private_endpoint_subnet is required when should_enable_private_endpoint is true."
  }
}

variable "resource_group" {
  description = "Resource group object containing name and id"
  type = object({
    id   = string
    name = string
  })
}

variable "virtual_network" {
  description = "Virtual network for private DNS zone linking. Required when should_create_private_dns_zone is true"
  type = object({
    id = string
  })
  default = null
}
