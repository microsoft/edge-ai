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

variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
}

variable "vm_username" {
  type        = string
  description = "Name for the user to create on the VM. If left empty, a random name will be generated"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
}

variable "arc_sp_client_id" {
  type        = string
  description = "Service Principal Client ID for connecting to Azure Arc"
}

variable "arc_sp_secret" {
  type        = string
  description = "Service Principal Secret for connecting to Azure Arc"
}

variable "add_current_entra_user_cluster_admin" {
  type        = bool
  description = "Only applies if 'environment!=prod'. Adds the current user as cluster-admin cluster role binding"
}
