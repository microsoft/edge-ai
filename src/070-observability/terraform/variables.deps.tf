/*
 * Required Variables
 */

variable "azmon_resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}
