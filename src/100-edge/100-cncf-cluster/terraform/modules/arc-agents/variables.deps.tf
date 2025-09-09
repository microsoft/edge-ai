/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "private_key_pem" {
  type        = string
  description = "Private key for onboarding"
}
