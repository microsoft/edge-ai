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

variable "existing_resource_group_name" {
  type        = string
  default     = ""
  description = "Name of the pre-existing resource group in which to create resources. If left empty, a new resource group will be created"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D4as_v4"
}

variable "vm_username" {
  type        = string
  description = "Name for the user to create on the VM. If left empty, a random name will be generated"
  default     = ""
}

variable "arc_sp_client_id" {
  type        = string
  description = "Service Principal Client ID for connecting to Azure Arc. If left empty, a new Service Principal will be created"
  default     = ""
}

variable "arc_sp_secret" {
  type        = string
  description = "Service Principal Secret for connecting to Azure Arc. If left empty, a new Service Principal will be created"
  default     = ""
  sensitive   = true
}
