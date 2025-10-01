/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
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

variable "nat_gateway" {
  type = object({
    id   = string
    name = string
  })
  description = "NAT gateway object from the networking component for managed outbound access"
  default     = null
}
