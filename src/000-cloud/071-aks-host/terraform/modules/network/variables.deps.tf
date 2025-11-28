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
  })
}
