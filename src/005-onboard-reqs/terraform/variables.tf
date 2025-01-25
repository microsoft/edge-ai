variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

variable "should_create_resource_group" {
  type        = bool
  description = "Should create and manage a new Resource Group."
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
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
