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

variable "existing_resource_group_name" {
  type        = string
  default     = null
  description = "Name of the pre-existing resource group in which to create resources. If left empty, a new resource group will be created"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "vm_username" {
  type        = string
  description = "Name for the user to create on the VM. If left empty, a random name will be generated"
  default     = null
}

variable "use_service_principal_for_arc_onboarding_instead_of_managed_identity" {
  type        = bool
  description = "If set to true, a new service principal will be created for connecting to Azure Arc. If set to false, a managed identity will be created instead."
  default     = false
}

variable "add_current_entra_user_cluster_admin" {
  type        = bool
  default     = false
  description = "Adds the current terraform user as cluster-admin cluster role binding"
}

variable "custom_locations_oid" {
  type        = string
  default     = null
  description = "The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions."
}
