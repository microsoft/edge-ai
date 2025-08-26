/*
 * Required Variables
 */

variable "adr_namespace" {
  type = object({
    id = string
  })
  description = "Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured."
}

variable "resource_group" {
  type = object({
    name = string
    id   = string
  })
  description = "Resource group object containing name and id where resources will be deployed."
}
