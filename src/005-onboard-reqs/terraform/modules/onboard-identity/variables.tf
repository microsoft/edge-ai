variable "resource_group_id" {
  type        = string
  description = "Resource group id to scope the role assignment to"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
}

variable "onboard_identity_type" {
  type        = string
  description = <<-EOF
    Identity type to use for onboarding the cluster to Azure Arc.

    - `uami`
    - `sp`
EOF
}
