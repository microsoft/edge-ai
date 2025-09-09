/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "aio_identity" {
  type = object({
    id           = string
    principal_id = string
    tenant_id    = string
    client_id    = string
  })
  description = "Azure IoT Operations managed identity for workspace access"
}
