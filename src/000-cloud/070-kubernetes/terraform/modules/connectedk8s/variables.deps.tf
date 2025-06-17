/*
 * Required Variables
 */

variable "resource_group" {
  description = "Resource group for all resources in this module."
  type = object({
    name = string
    id   = string
  })
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
  description = "Azure Container Registry."
  type = object({
    id = string
  })
}
