/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "snet_aks" {
  description = "Subnet for the AKS vnet."
  type = object({
    id = string
  })
}

variable "snet_aks_pod" {
  description = "Subnet for the AKS pod vnet."
  type = object({
    id = string
  })
}

variable "acr" {
  type = object({
    id = string
  })
  description = "Azure Container Registry"
}
