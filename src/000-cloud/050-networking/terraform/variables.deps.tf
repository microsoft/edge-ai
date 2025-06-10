/*
 * Dependency Variables - Resources from other components
 */

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "The resource group to deploy the virtual network in."
}
