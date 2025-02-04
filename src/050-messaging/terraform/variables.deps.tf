/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}

variable "aio_user_assigned_identity" {
  type = object({
    id           = string
    principal_id = string
    tenant_id    = string
    client_id    = string
  })
}

variable "aio_custom_locations" {
  type = object({
    name = string
    id   = string
  })
}

variable "aio_instance" {
  type = object({
    id = string
  })
}

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
}
