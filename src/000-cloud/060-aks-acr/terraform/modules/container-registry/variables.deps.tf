/*
 * Required Variables
 */

variable "resource_group" {
  description = "Resource group for all resources in this module."
  type = object({
    name = string
  })
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
