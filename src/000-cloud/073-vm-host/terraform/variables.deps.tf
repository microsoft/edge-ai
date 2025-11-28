/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to deploy the VM host in"
}

/*
 * Optional Variables
 */

variable "arc_onboarding_identity" {
  type = object({
    id = string
  })
  description = "The Principal ID for the identity that will be used for onboarding the cluster to Arc"
  default     = null
}
