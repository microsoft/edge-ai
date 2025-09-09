/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = string
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

variable "acr" {
  type = object({
    id = string
  })
  description = "Azure Container Registry"
}
