/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}