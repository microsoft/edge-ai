/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}

variable "private_key_pem" {
  type        = string
  description = "Private key for onboarding"
}
