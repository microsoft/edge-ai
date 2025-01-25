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

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "vm_username" {
  type        = string
  description = "Name for the VM user to create on the target VM. If left empty, a random user name will be generated"
  default     = null
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "arc_onboarding_user_managed_identity_name" {
  type        = string
  description = "If using, the User Assigned Managed Identity name with 'Kubernetes Cluster - Azure Arc Onboarding' permissions."
  default     = null
}

variable "enable_arc_onboarding_user_managed_identity" {
  type    = string
  default = true
}
