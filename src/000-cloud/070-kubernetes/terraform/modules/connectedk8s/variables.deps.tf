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
