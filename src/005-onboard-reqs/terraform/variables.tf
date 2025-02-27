variable "should_create_resource_group" {
  type        = bool
  description = "Should create and manage a new Resource Group."
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
  default     = null
}

variable "should_create_onboard_identity" {
  type        = bool
  description = "Should create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc."
  default     = true
}

variable "onboard_identity_type" {
  type        = string
  description = <<-EOF
    Identity type to use for onboarding the cluster to Azure Arc.

    Allowed values:

    - uami
    - sp
EOF
  default     = "uami"
  validation {
    condition     = contains(["uami", "sp"], var.onboard_identity_type)
    error_message = "Must be one of ['uami', 'sp']."
  }
}
