/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    id       = string
    name     = string
    location = string
  })
  description = "Resource group object containing name and id"
}

variable "virtual_network" {
  type = object({
    id   = string
    name = string
  })
  description = "Virtual network object for VPN Gateway subnet creation"
}

/*
 * Optional Variables
 */

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "Key Vault object for certificate storage. Required when using auto-generated certificates"
  default     = null
}
