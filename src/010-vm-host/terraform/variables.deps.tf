/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name = string
  })
}

/*
 * Optional Variables
 */

variable "arc_onboarding_user_assigned_identity" {
  type = object({
    id = string
  })
  default = null
}
