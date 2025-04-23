/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "network_security_group" {
  type = object({
    id = string
  })
}

variable "virtual_network" {
  type = object({
    name = string
    id   = string
  })
}
