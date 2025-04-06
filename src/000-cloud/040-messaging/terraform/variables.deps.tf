/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}

variable "aio_identity" {
  type = object({
    id           = string
    principal_id = string
    tenant_id    = string
    client_id    = string
  })
}
