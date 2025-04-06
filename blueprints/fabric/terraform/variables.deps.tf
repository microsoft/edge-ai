/*
 * Optional
 */

variable "resource_group" {
  type = object({
    name = string
  })
  default = null
}
