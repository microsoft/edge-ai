/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "The resource group to deploy the VM host in."
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to deploy the VM host in."
}

/*
 * Optional Variables
 */

variable "arc_onboarding_identity" {
  type = object({
    id = string
  })
  description = "The identity for Arc onboarding."
  default     = null
}
