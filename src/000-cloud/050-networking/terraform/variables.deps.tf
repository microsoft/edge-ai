/*
 * Dependency Variables - Resources from other components
 */

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}
