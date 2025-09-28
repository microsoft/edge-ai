/*
 * Required Variables
 */

variable "azmon_resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
  description = "The resource group object containing name and id for observability resources."
}
