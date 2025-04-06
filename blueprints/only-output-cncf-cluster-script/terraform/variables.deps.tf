/*
 * Optional Variables
 */

variable "aio_resource_group_name" {
  type        = string
  description = <<-EOF
    The name of the Resource Group that will be used to connect the new cluster to Azure Arc.
    (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}' Does not need to exist for output script)"
EOF
  default     = null
}

/*
 * Optional Variables
 */

variable "arc_onboarding_identity_name" {
  description = "The Principal ID for the identity that will be used for onboarding the cluster to Arc."
  type        = string
  default     = null
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
