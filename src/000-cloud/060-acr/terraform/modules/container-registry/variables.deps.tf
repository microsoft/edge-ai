/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "snet_acr" {
  description = "Subnet for the Azure Container Registry private endpoint."
  type = object({
    id = string
  })
}

variable "vnet" {
  description = "Virtual Network for Container Registry Private DNS Zone."
  type = object({
    id = string
  })
}
