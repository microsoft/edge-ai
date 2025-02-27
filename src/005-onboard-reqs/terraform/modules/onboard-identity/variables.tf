variable "resource_group_id" {
  type        = string
  description = "The ID for the Resource Group for the resources."
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
  description = "The name for the resource group."
}

variable "onboard_identity_type" {
  type        = string
  description = <<-EOF
    Identity type to use for onboarding the cluster to Azure Arc.

    Allowed values:

    - uami
    - sp
EOF
}
