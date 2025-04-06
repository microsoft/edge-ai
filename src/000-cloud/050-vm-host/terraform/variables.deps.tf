/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
}

/*
 * Optional Variables
 */

variable "arc_onboarding_identity" {
  type = object({
    id = string
  })
  default = null
}
