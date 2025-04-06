/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    id       = string
    name     = string
    location = string
  })
}
