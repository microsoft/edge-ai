/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}

/*
 * Optional Variables
 */

variable "cluster_server_virtual_machine" {
  type = object({
    id = string
  })
  default = null
}

variable "cluster_node_virtual_machines" {
  type = list(object({
    id = string
  }))
  default = null
}

variable "arc_onboarding_identity" {
  description = "The Principal ID for the identity that will be used for onboarding the cluster to Arc."
  type = object({
    principal_id = string
  })
  default = null

  validation {
    condition     = !var.should_assign_roles || anytrue([var.arc_onboarding_identity != null, var.arc_onboarding_sp != null])
    error_message = "Either 'arc_onboarding_identity' or 'arc_onboarding_sp' required when should_assign_roles is 'true'"
  }
}

variable "arc_onboarding_sp" {
  type = object({
    client_id     = string
    object_id     = string
    client_secret = string
  })
  sensitive = true
  default   = null
}
