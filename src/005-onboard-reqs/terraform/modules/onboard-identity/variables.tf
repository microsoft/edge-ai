variable "resource_group_id" {
  type        = string
  description = "The ID for the Resource Group for the resources."
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
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
